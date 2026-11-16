import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { IntegrationEventsService } from '../integration/integration-events.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  pointsEarnedMessage,
  pointsReversedMessage,
  pointsSpentMessage,
} from '../notifications/messages';
import {
  CoffeeSize,
  CoffeePunchCard,
  LoyaltyTxSource,
  LoyaltyTxType,
  Prisma,
  UserRole,
} from '@prisma/client';
import type { AuthUser } from '../auth/types/auth-user';
import {
  EarnPointsDto,
  QueryTransactionsDto,
  RedeemPointsDto,
} from './dto/staff-points.dto';

/** Prefix of the one-time QR token shown in the app (vs. the permanent qrCode). */
export const QR_TOKEN_PREFIX = 'T:';
export const QR_TOKEN_TTL_SECONDS = 60;
/** Lifetime of a token given back after a failed debit. */
const QR_TOKEN_RESTORE_SECONDS = 30;
const qrTokenKey = (token: string) => `loyalty:qr:${token}`;

export interface ApplyPointsInput {
  userId: string;
  type: LoyaltyTxType;
  source: LoyaltyTxSource;
  /** Signed: positive credits, negative debits; 0 only for FREE_COFFEE. */
  points: number;
  description?: string;
  orderId?: string;
  storeId?: string | null;
  staffId?: string;
  receiptNumber?: string;
  receiptAmount?: Prisma.Decimal | number;
  reversalOfId?: string;
}

const TX_SELECT = {
  id: true,
  type: true,
  source: true,
  points: true,
  balanceAfter: true,
  description: true,
  receiptNumber: true,
  receiptAmount: true,
  createdAt: true,
  reversalOfId: true,
  reversedBy: { select: { id: true } },
  user: { select: { id: true, phone: true, firstName: true, lastName: true } },
  staff: { select: { id: true, phone: true, firstName: true, lastName: true } },
  store: { select: { id: true, name: true } },
  order: { select: { id: true, orderNumber: true } },
} satisfies Prisma.LoyaltyTransactionSelect;

export interface LoyaltyTransaction {
  id: string;
  type: 'earned' | 'used' | 'refunded';
  points: number;
  description: string;
  orderId?: string;
  orderNumber?: string;
  createdAt: Date;
}

export interface PunchCard {
  id: string;
  size: CoffeeSize;
  sizeName: string;
  currentPunches: number;
  maxPunches: number;
  isComplete: boolean;
  freeItemClaimed: boolean;
  createdAt: Date;
  completedAt?: Date;
}

@Injectable()
export class LoyaltyService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private integrationEvents: IntegrationEventsService,
    private notifications: NotificationsService,
  ) {}

  // ==================== LEDGER ====================

  /**
   * The only way to change a user's points. Updates the balance and writes
   * the ledger row in the caller's transaction. A debit never takes the
   * balance below zero (conditional update, safe under concurrency).
   */
  async applyPoints(tx: Prisma.TransactionClient, input: ApplyPointsInput) {
    if (!Number.isInteger(input.points)) {
      throw new BadRequestException('Points must be a whole number');
    }

    let balanceAfter: number;
    if (input.points < 0) {
      const { count } = await tx.user.updateMany({
        where: { id: input.userId, loyaltyPoints: { gte: -input.points } },
        data: { loyaltyPoints: { increment: input.points } },
      });
      if (count === 0) {
        throw new BadRequestException('Not enough loyalty points');
      }
      const user = await tx.user.findUniqueOrThrow({
        where: { id: input.userId },
        select: { loyaltyPoints: true },
      });
      balanceAfter = user.loyaltyPoints;
    } else if (input.points > 0) {
      const user = await tx.user.update({
        where: { id: input.userId },
        data: { loyaltyPoints: { increment: input.points } },
        select: { loyaltyPoints: true },
      });
      balanceAfter = user.loyaltyPoints;
    } else {
      const user = await tx.user.findUniqueOrThrow({
        where: { id: input.userId },
        select: { loyaltyPoints: true },
      });
      balanceAfter = user.loyaltyPoints;
    }

    let row: { id: string; createdAt: Date };
    try {
      row = await tx.loyaltyTransaction.create({
        data: {
          userId: input.userId,
          type: input.type,
          source: input.source,
          points: input.points,
          balanceAfter,
          description: input.description,
          orderId: input.orderId,
          storeId: input.storeId ?? undefined,
          staffId: input.staffId,
          receiptNumber: input.receiptNumber,
          receiptAmount: input.receiptAmount,
          reversalOfId: input.reversalOfId,
        },
        select: { id: true, createdAt: true },
      });
    } catch (e) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        throw new ConflictException(
          input.reversalOfId
            ? 'Operation is already cancelled'
            : 'This receipt has already been processed',
        );
      }
      throw e;
    }

    await this.integrationEvents.record(tx, 'loyalty.transaction', row.id, {
      userId: input.userId,
      type: input.type,
      source: input.source,
      points: input.points,
      balanceAfter,
      storeId: input.storeId ?? null,
      orderId: input.orderId ?? null,
      receiptNumber: input.receiptNumber ?? null,
    });

    return { id: row.id, balanceAfter };
  }

  // ==================== QR ====================

  /**
   * Short-lived token for the QR shown in the app. Redeeming points requires
   * it, so a screenshot of someone's QR code cannot be used to spend points.
   */
  async issueQrToken(userId: string) {
    const token = randomBytes(9).toString('base64url');
    await this.redis.set(qrTokenKey(token), userId, QR_TOKEN_TTL_SECONDS);
    return {
      code: `${QR_TOKEN_PREFIX}${token}`,
      expiresIn: QR_TOKEN_TTL_SECONDS,
    };
  }

  /** Finds the customer by a one-time token or the permanent QR code. */
  private async resolveCustomer(
    code: string,
    opts: { requireToken?: boolean } = {},
  ) {
    const trimmed = code.trim();
    let userId: string | null = null;

    if (trimmed.startsWith(QR_TOKEN_PREFIX)) {
      const key = qrTokenKey(trimmed.slice(QR_TOKEN_PREFIX.length));
      userId = await this.redis.get(key);
      if (!userId) {
        throw new BadRequestException(
          'QR code has expired, ask the customer to refresh it',
        );
      }
    } else if (opts.requireToken) {
      throw new BadRequestException(
        'To spend points scan the live QR code from the app',
      );
    }

    const user = await this.prisma.user.findUnique({
      where: userId ? { id: userId } : { qrCode: trimmed },
      select: {
        id: true,
        phone: true,
        firstName: true,
        lastName: true,
        loyaltyPoints: true,
        isActive: true,
        qrCode: true,
      },
    });

    if (!user || !user.isActive) {
      throw new NotFoundException('Customer not found');
    }
    return user;
  }

  // ==================== CASH DESK ====================

  /** Store of the cash desk: staff use their own, admins must choose one. */
  private cashDeskStore(actor: AuthUser, requested?: string): string {
    if (actor.role === UserRole.STORE_STAFF) {
      if (!actor.storeId) {
        throw new ForbiddenException('Employee is not assigned to a store');
      }
      return actor.storeId;
    }
    if (actor.role === UserRole.ADMIN && requested) {
      return requested;
    }
    throw new BadRequestException('Store is required');
  }

  async earnInStore(actor: AuthUser, dto: EarnPointsDto) {
    const storeId = this.cashDeskStore(actor, dto.storeId);
    const settings = await this.getSettings();
    const customer = await this.resolveCustomer(dto.code);

    if (customer.id === actor.id) {
      throw new ForbiddenException('You cannot credit points to yourself');
    }
    if (dto.receiptAmount > settings.maxReceiptAmount) {
      throw new BadRequestException(
        `Receipt amount exceeds the limit of ${settings.maxReceiptAmount} som`,
      );
    }

    const amount = new Prisma.Decimal(dto.receiptAmount);
    const points = amount
      .mul(settings.cashbackPercent)
      .div(100)
      .floor()
      .toNumber();
    if (points <= 0) {
      throw new BadRequestException('Receipt amount is too small for cashback');
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const earned = await tx.loyaltyTransaction.aggregate({
        where: {
          userId: customer.id,
          type: LoyaltyTxType.EARN,
          source: LoyaltyTxSource.IN_STORE,
          createdAt: { gte: since },
        },
        _sum: { points: true },
      });
      if ((earned._sum.points ?? 0) + points > settings.dailyEarnLimit) {
        throw new BadRequestException(
          `Daily cashback limit of ${settings.dailyEarnLimit} points reached`,
        );
      }

      return this.applyPoints(tx, {
        userId: customer.id,
        type: LoyaltyTxType.EARN,
        source: LoyaltyTxSource.IN_STORE,
        points,
        description: `Кешбэк за покупку, чек ${dto.receiptNumber}`,
        storeId,
        staffId: actor.id,
        receiptNumber: dto.receiptNumber,
        receiptAmount: amount,
      });
    });

    await this.notifications.notify(
      customer.id,
      pointsEarnedMessage(points, result.balanceAfter),
    );
    return { transactionId: result.id, points, balance: result.balanceAfter };
  }

  async redeemInStore(actor: AuthUser, dto: RedeemPointsDto) {
    const storeId = this.cashDeskStore(actor, dto.storeId);
    const settings = await this.getSettings();
    // Validate everything first so a typo does not burn the customer's QR
    const customer = await this.resolveCustomer(dto.code, {
      requireToken: true,
    });

    if (customer.id === actor.id) {
      throw new ForbiddenException('You cannot spend your own points here');
    }

    const amount = new Prisma.Decimal(dto.receiptAmount);
    const maxPoints = amount
      .mul(settings.maxPointsUsePercent)
      .div(100)
      .floor()
      .toNumber();
    if (dto.points > maxPoints) {
      throw new BadRequestException(
        `At most ${maxPoints} points can be used for this receipt`,
      );
    }

    // One scan of the live QR allows one debit: claim the token atomically
    // (two concurrent requests cannot both get it) and give it back if the
    // debit itself fails, e.g. not enough points
    const tokenKey = qrTokenKey(dto.code.trim().slice(QR_TOKEN_PREFIX.length));
    const claimedBy = await this.redis.getDel(tokenKey);
    if (claimedBy !== customer.id) {
      throw new BadRequestException(
        'QR code has expired, ask the customer to refresh it',
      );
    }

    let result: { id: string; balanceAfter: number };
    try {
      result = await this.prisma.$transaction((tx) =>
        this.applyPoints(tx, {
          userId: customer.id,
          type: LoyaltyTxType.REDEEM,
          source: LoyaltyTxSource.IN_STORE,
          points: -dto.points,
          description: `Оплата баллами, чек ${dto.receiptNumber}`,
          storeId,
          staffId: actor.id,
          receiptNumber: dto.receiptNumber,
          receiptAmount: amount,
        }),
      );
    } catch (e) {
      await this.redis.set(tokenKey, customer.id, QR_TOKEN_RESTORE_SECONDS);
      throw e;
    }

    await this.notifications.notify(
      customer.id,
      pointsSpentMessage(dto.points, result.balanceAfter),
    );
    return {
      transactionId: result.id,
      points: dto.points,
      balance: result.balanceAfter,
    };
  }

  /** Admin: cancel an operation by writing the opposite entry. */
  async reverseTransaction(actor: AuthUser, id: string, reason?: string) {
    const original = await this.prisma.loyaltyTransaction.findUnique({
      where: { id },
      select: {
        id: true,
        type: true,
        points: true,
        userId: true,
        storeId: true,
        receiptNumber: true,
      },
    });
    if (!original) {
      throw new NotFoundException('Transaction not found');
    }
    if (
      original.type === LoyaltyTxType.REVERSAL ||
      original.type === LoyaltyTxType.FREE_COFFEE ||
      original.points === 0
    ) {
      throw new BadRequestException('This operation cannot be cancelled');
    }

    const result = await this.prisma.$transaction((tx) =>
      this.applyPoints(tx, {
        userId: original.userId,
        type: LoyaltyTxType.REVERSAL,
        source: LoyaltyTxSource.MANUAL,
        points: -original.points,
        description: `Отмена операции${original.receiptNumber ? `, чек ${original.receiptNumber}` : ''}${reason ? `: ${reason}` : ''}`,
        storeId: original.storeId,
        staffId: actor.id,
        reversalOfId: original.id,
      }),
    );

    await this.notifications.notify(
      original.userId,
      pointsReversedMessage(-original.points, result.balanceAfter),
    );
    return { transactionId: result.id, balance: result.balanceAfter };
  }

  /** Operations report for reconciliation with the cash register. */
  async listTransactions(actor: AuthUser, query: QueryTransactionsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 50;

    const where: Prisma.LoyaltyTransactionWhereInput = {
      type: query.type,
      source: query.source,
      staffId: query.staffId,
    };
    if (actor.role === UserRole.STORE_STAFF) {
      where.storeId = this.cashDeskStore(actor);
    } else if (query.storeId) {
      where.storeId = query.storeId;
    }
    if (query.from || query.to) {
      where.createdAt = {
        gte: query.from ? new Date(query.from) : undefined,
        lt: query.to ? new Date(query.to) : undefined,
      };
    }

    const [rows, total, sums] = await this.prisma.$transaction([
      this.prisma.loyaltyTransaction.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: TX_SELECT,
      }),
      this.prisma.loyaltyTransaction.count({ where }),
      this.prisma.loyaltyTransaction.groupBy({
        by: ['type'],
        where,
        orderBy: { type: 'asc' },
        _sum: { points: true, receiptAmount: true },
        _count: { _all: true },
      }),
    ]);

    return {
      data: rows.map((r) => ({
        ...r,
        receiptAmount: r.receiptAmount ? Number(r.receiptAmount) : null,
        reversedBy: undefined,
        isReversed: !!r.reversedBy,
      })),
      totals: sums.map((s) => ({
        type: s.type,
        count: (s._count as { _all: number })._all,
        points: s._sum?.points ?? 0,
        receiptAmount: Number(s._sum?.receiptAmount ?? 0),
      })),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async getBalance(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        loyaltyPoints: true,
        qrCode: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Calculate loyalty level based on points
    const level = this.calculateLoyaltyLevel(user.loyaltyPoints);

    return {
      points: user.loyaltyPoints,
      qrCode: user.qrCode,
      level,
    };
  }

  private calculateLoyaltyLevel(points: number): string {
    if (points >= 10000) {
      return 'Platinum';
    } else if (points >= 5000) {
      return 'Gold';
    } else if (points >= 1000) {
      return 'Silver';
    }
    return 'Bronze';
  }

  async getHistory(userId: string): Promise<LoyaltyTransaction[]> {
    const rows = await this.prisma.loyaltyTransaction.findMany({
      where: { userId, points: { not: 0 } },
      orderBy: { createdAt: 'desc' },
      take: 200,
      select: {
        id: true,
        type: true,
        points: true,
        description: true,
        createdAt: true,
        order: { select: { id: true, orderNumber: true } },
      },
    });

    return rows.map((row) => ({
      id: row.id,
      type:
        row.type === LoyaltyTxType.REFUND
          ? 'refunded'
          : row.points > 0
            ? 'earned'
            : 'used',
      points: row.points,
      description: row.description ?? '',
      orderId: row.order?.id,
      orderNumber: row.order?.orderNumber,
      createdAt: row.createdAt,
    }));
  }

  async getSettings() {
    const settings = await this.prisma.settings.findMany({
      where: {
        key: {
          in: [
            'loyalty_cashback_percent',
            'loyalty_max_points_use_percent',
            'delivery_fee',
            'free_delivery_min_amount',
            'loyalty_max_receipt_amount',
            'loyalty_daily_earn_limit',
            'prepayment_timeout_minutes',
          ],
        },
      },
    });

    const settingsMap = new Map(settings.map((s) => [s.key, s.value]));

    return {
      cashbackPercent: parseInt(
        settingsMap.get('loyalty_cashback_percent') || '5',
        10,
      ),
      maxPointsUsePercent: parseInt(
        settingsMap.get('loyalty_max_points_use_percent') || '100',
        10,
      ),
      pointValue: 1, // 1 point = 1 som
      deliveryFee: parseInt(settingsMap.get('delivery_fee') || '100', 10),
      freeDeliveryMinAmount: parseInt(
        settingsMap.get('free_delivery_min_amount') || '1000',
        10,
      ),
      // Cash desk safeguards
      maxReceiptAmount: parseInt(
        settingsMap.get('loyalty_max_receipt_amount') || '50000',
        10,
      ),
      dailyEarnLimit: parseInt(
        settingsMap.get('loyalty_daily_earn_limit') || '2000',
        10,
      ),
      // Unpaid made-to-order orders are cancelled after this
      prepaymentTimeoutMinutes: parseInt(
        settingsMap.get('prepayment_timeout_minutes') || '60',
        10,
      ),
      rules: [
        {
          title: 'Начисление баллов',
          titleRu: 'Начисление баллов',
          titleKy: 'Упай чогултуу',
          description: `За каждый заказ вы получаете ${settingsMap.get('loyalty_cashback_percent') || '5'}% кешбэк в виде баллов`,
          descriptionRu: `За каждый заказ вы получаете ${settingsMap.get('loyalty_cashback_percent') || '5'}% кешбэк в виде баллов`,
          descriptionKy: `Ар бир заказ үчүн сиз ${settingsMap.get('loyalty_cashback_percent') || '5'}% кешбэк упай түрүндө аласыз`,
        },
        {
          title: 'Использование баллов',
          titleRu: 'Использование баллов',
          titleKy: 'Упайларды колдонуу',
          description: `1 балл = 1 сом. Можно оплатить до ${settingsMap.get('loyalty_max_points_use_percent') || '100'}% заказа баллами`,
          descriptionRu: `1 балл = 1 сом. Можно оплатить до ${settingsMap.get('loyalty_max_points_use_percent') || '100'}% заказа баллами`,
          descriptionKy: `1 упай = 1 сом. Заказдын ${settingsMap.get('loyalty_max_points_use_percent') || '100'}%ине чейин упай менен төлөсө болот`,
        },
        {
          title: 'Срок действия',
          titleRu: 'Срок действия',
          titleKy: 'Жарактуулук мөөнөтү',
          description: 'Баллы не сгорают',
          descriptionRu: 'Баллы не сгорают',
          descriptionKy: 'Упайлар күйбөйт',
        },
      ],
    };
  }

  // ==================== PUNCH CARDS ====================

  private getSizeName(size: CoffeeSize): string {
    const names = {
      S: 'Кофе S',
      M: 'Кофе M',
      L: 'Кофе L',
    };
    return names[size];
  }

  async getPunchCards(userId: string): Promise<PunchCard[]> {
    // Get all punch cards for user, create missing ones
    const existingCards = await this.prisma.coffeePunchCard.findMany({
      where: { userId },
    });

    // Ensure all sizes exist
    const sizes: CoffeeSize[] = ['S', 'M', 'L'];
    const existingSizes = new Set(existingCards.map((c) => c.size));

    const cardsToCreate = sizes.filter((size) => !existingSizes.has(size));

    if (cardsToCreate.length > 0) {
      await this.prisma.coffeePunchCard.createMany({
        data: cardsToCreate.map((size) => ({
          userId,
          size,
          currentPunches: 0,
          maxPunches: 6,
        })),
        skipDuplicates: true,
      });
    }

    // Fetch all cards again
    const allCards = await this.prisma.coffeePunchCard.findMany({
      where: { userId },
      orderBy: { size: 'asc' },
    });

    return allCards.map((card) => this.formatPunchCard(card));
  }

  /**
   * Adds punches to the user's card. Must be called inside the transaction
   * that marks the order as delivered, so punches are not awarded twice.
   */
  async addPunch(
    tx: Prisma.TransactionClient,
    userId: string,
    size: CoffeeSize,
    count: number = 1,
  ): Promise<PunchCard> {
    const card = await tx.coffeePunchCard.upsert({
      where: { userId_size: { userId, size } },
      create: { userId, size, currentPunches: 0, maxPunches: 6 },
      update: {},
    });

    // Punches beyond maxPunches are not accumulated until the free coffee is given out
    const newPunches = Math.min(card.currentPunches + count, card.maxPunches);
    const isComplete = newPunches >= card.maxPunches;

    const updated = await tx.coffeePunchCard.update({
      where: { id: card.id },
      data: {
        currentPunches: newPunches,
        completedAt:
          isComplete && !card.completedAt ? new Date() : card.completedAt,
      },
    });

    return this.formatPunchCard(updated);
  }

  /** Staff: find a customer by the QR code (permanent or one-time). */
  async findCustomer(code: string) {
    const user = await this.resolveCustomer(code);
    const [punchCards, settings] = await Promise.all([
      this.getPunchCards(user.id),
      this.getSettings(),
    ]);

    return {
      id: user.id,
      phone: user.phone,
      firstName: user.firstName,
      lastName: user.lastName,
      loyaltyPoints: user.loyaltyPoints,
      level: this.calculateLoyaltyLevel(user.loyaltyPoints),
      punchCards,
      // Lets the cash desk show cashback and the redeem limit before saving
      cashbackPercent: settings.cashbackPercent,
      maxPointsUsePercent: settings.maxPointsUsePercent,
      /** Only a live QR from the app allows spending points. */
      canRedeem: code.trim().startsWith(QR_TOKEN_PREFIX),
      /**
       * Permanent code for crediting cashback and giving coffee after the
       * one-time token has been used up by a debit.
       */
      customerCode: user.qrCode,
    };
  }

  /**
   * Staff: give out the free coffee for a completed card and reset the card.
   * The conditional update makes double-claiming impossible even under
   * concurrency; the ledger records who gave it out and where.
   */
  async claimFreeCoffee(
    actor: AuthUser,
    code: string,
    size: CoffeeSize,
  ): Promise<PunchCard> {
    const user = await this.resolveCustomer(code);

    return this.prisma.$transaction(async (tx) => {
      const card = await tx.coffeePunchCard.findUnique({
        where: { userId_size: { userId: user.id, size } },
      });

      if (!card) {
        throw new NotFoundException('Punch card not found');
      }

      const { count } = await tx.coffeePunchCard.updateMany({
        where: {
          id: card.id,
          currentPunches: { gte: card.maxPunches },
        },
        data: {
          currentPunches: 0,
          freeItemClaimed: false,
          completedAt: null,
        },
      });

      if (count === 0) {
        throw new BadRequestException('Punch card is not complete');
      }

      await this.applyPoints(tx, {
        userId: user.id,
        type: LoyaltyTxType.FREE_COFFEE,
        source: LoyaltyTxSource.IN_STORE,
        points: 0,
        description: `Бесплатный ${this.getSizeName(size)}`,
        storeId: actor.storeId,
        staffId: actor.id,
      });

      const updated = await tx.coffeePunchCard.findUniqueOrThrow({
        where: { id: card.id },
      });

      return this.formatPunchCard(updated);
    });
  }

  private formatPunchCard(card: CoffeePunchCard): PunchCard {
    return {
      id: card.id,
      size: card.size,
      sizeName: this.getSizeName(card.size),
      currentPunches: card.currentPunches,
      maxPunches: card.maxPunches,
      isComplete: card.currentPunches >= card.maxPunches,
      freeItemClaimed: card.freeItemClaimed,
      createdAt: card.createdAt,
      completedAt: card.completedAt || undefined,
    };
  }
}
