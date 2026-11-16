import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { LoyaltyService } from './loyalty.service';
import { AuthUser } from '../auth/types/auth-user';

const STAFF: AuthUser = {
  id: 'staff-1',
  phone: '+996700000001',
  role: UserRole.STORE_STAFF,
  storeId: 'store-1',
};
const ADMIN: AuthUser = {
  id: 'admin-1',
  phone: '+996700000000',
  role: UserRole.ADMIN,
  storeId: null,
};

/**
 * Minimal in-memory stand-in for the Prisma calls LoyaltyService makes:
 * users with balances, the ledger with its unique keys, punch cards.
 */
function makeDb() {
  const users = new Map<string, any>([
    [
      'user-1',
      {
        id: 'user-1',
        phone: '+996700111111',
        qrCode: 'qr-1',
        loyaltyPoints: 100,
        isActive: true,
      },
    ],
    [
      'staff-1',
      {
        id: 'staff-1',
        phone: '+996700000001',
        qrCode: 'qr-staff',
        loyaltyPoints: 0,
        isActive: true,
      },
    ],
  ]);
  const txs: any[] = [];
  let card: any = {
    id: 'card-1',
    userId: 'user-1',
    size: 'M',
    currentPunches: 6,
    maxPunches: 6,
    freeItemClaimed: false,
    createdAt: new Date(),
    completedAt: new Date(),
  };

  const findUser = (where: any) =>
    where.id
      ? users.get(where.id)
      : [...users.values()].find((u) => u.qrCode === where.qrCode);

  const prisma: any = {
    user: {
      findUnique: jest.fn(async ({ where }: any) => findUser(where) ?? null),
      findUniqueOrThrow: jest.fn(async ({ where }: any) => findUser(where)),
      update: jest.fn(async ({ where, data }: any) => {
        const u = users.get(where.id);
        u.loyaltyPoints += data.loyaltyPoints.increment;
        return u;
      }),
      updateMany: jest.fn(async ({ where, data }: any) => {
        const u = users.get(where.id);
        if (!u || u.loyaltyPoints < where.loyaltyPoints.gte)
          return { count: 0 };
        u.loyaltyPoints += data.loyaltyPoints.increment;
        return { count: 1 };
      }),
    },
    loyaltyTransaction: {
      create: jest.fn(async ({ data }: any) => {
        const dup = txs.find(
          (t) =>
            (data.receiptNumber &&
              t.storeId === data.storeId &&
              t.receiptNumber === data.receiptNumber &&
              t.type === data.type) ||
            (data.reversalOfId && t.reversalOfId === data.reversalOfId),
        );
        if (dup) {
          throw new Prisma.PrismaClientKnownRequestError('Unique', {
            code: 'P2002',
            clientVersion: 'test',
          });
        }
        const row = {
          id: `tx-${txs.length + 1}`,
          createdAt: new Date(),
          ...data,
        };
        txs.push(row);
        return row;
      }),
      findUnique: jest.fn(
        async ({ where }: any) => txs.find((t) => t.id === where.id) ?? null,
      ),
      aggregate: jest.fn(async ({ where }: any) => ({
        _sum: {
          points: txs
            .filter(
              (t) =>
                t.userId === where.userId &&
                t.type === where.type &&
                t.source === where.source,
            )
            .reduce((sum, t) => sum + t.points, 0),
        },
      })),
    },
    coffeePunchCard: {
      findMany: jest.fn(async () => [card]),
      createMany: jest.fn(),
      findUnique: jest.fn(async () => card),
      findUniqueOrThrow: jest.fn(async () => card),
      updateMany: jest.fn(async ({ where, data }: any) => {
        if (card.currentPunches < where.currentPunches.gte) return { count: 0 };
        card = { ...card, ...data };
        return { count: 1 };
      }),
    },
    settings: {
      findMany: jest.fn(async () => [
        { key: 'loyalty_cashback_percent', value: '5' },
        { key: 'loyalty_max_points_use_percent', value: '50' },
        { key: 'loyalty_max_receipt_amount', value: '50000' },
        { key: 'loyalty_daily_earn_limit', value: '100' },
      ]),
    },
    $transaction: jest.fn(async (arg: any) =>
      Array.isArray(arg) ? Promise.all(arg) : arg(prisma),
    ),
  };

  const redisStore = new Map<string, string>();
  const redis: any = {
    set: jest.fn(async (k: string, v: string) => {
      redisStore.set(k, v);
    }),
    get: jest.fn(async (k: string) => redisStore.get(k) ?? null),
    getDel: jest.fn(async (k: string) => {
      const v = redisStore.get(k) ?? null;
      redisStore.delete(k);
      return v;
    }),
  };
  const events: any = { record: jest.fn() };

  return { prisma, redis, events, users, txs };
}

describe('LoyaltyService', () => {
  let db: ReturnType<typeof makeDb>;
  let service: LoyaltyService;

  beforeEach(() => {
    db = makeDb();
    service = new LoyaltyService(db.prisma, db.redis, db.events, {
      notify: jest.fn(),
    } as any);
  });

  const balance = () => db.users.get('user-1').loyaltyPoints;
  const ledgerSum = () =>
    db.txs
      .filter((t) => t.userId === 'user-1')
      .reduce((s, t) => s + t.points, 0);

  describe('applyPoints', () => {
    it('keeps balance and ledger in step and records an event', async () => {
      const r = await service.applyPoints(db.prisma, {
        userId: 'user-1',
        type: 'EARN',
        source: 'APP_ORDER',
        points: 30,
      });
      expect(r.balanceAfter).toBe(130);
      expect(db.txs[0]).toMatchObject({ points: 30, balanceAfter: 130 });
      expect(db.events.record).toHaveBeenCalledWith(
        db.prisma,
        'loyalty.transaction',
        'tx-1',
        expect.objectContaining({ points: 30 }),
      );
    });

    it('never takes the balance below zero', async () => {
      await expect(
        service.applyPoints(db.prisma, {
          userId: 'user-1',
          type: 'REDEEM',
          source: 'IN_STORE',
          points: -101,
        }),
      ).rejects.toThrow('Not enough loyalty points');
      expect(balance()).toBe(100);
      expect(db.txs).toHaveLength(0);
    });
  });

  describe('cash desk', () => {
    it('credits cashback for a receipt', async () => {
      const r = await service.earnInStore(STAFF, {
        code: 'qr-1',
        receiptNumber: 'A-1',
        receiptAmount: 999,
      });
      expect(r).toMatchObject({ points: 49, balance: 149 });
      expect(db.txs[0]).toMatchObject({
        storeId: 'store-1',
        staffId: 'staff-1',
      });
    });

    it('rejects the same receipt twice', async () => {
      const dto = { code: 'qr-1', receiptNumber: 'A-1', receiptAmount: 500 };
      await service.earnInStore(STAFF, dto);
      await expect(service.earnInStore(STAFF, dto)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('enforces the daily cashback limit', async () => {
      await service.earnInStore(STAFF, {
        code: 'qr-1',
        receiptNumber: 'A-1',
        receiptAmount: 1800,
      });
      await expect(
        service.earnInStore(STAFF, {
          code: 'qr-1',
          receiptNumber: 'A-2',
          receiptAmount: 400,
        }),
      ).rejects.toThrow('Daily cashback limit');
    });

    it('does not let staff credit themselves', async () => {
      await expect(
        service.earnInStore(STAFF, {
          code: 'qr-staff',
          receiptNumber: 'A-1',
          receiptAmount: 500,
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('requires a store for admins', async () => {
      await expect(
        service.earnInStore(ADMIN, {
          code: 'qr-1',
          receiptNumber: 'A-1',
          receiptAmount: 500,
        }),
      ).rejects.toThrow('Store is required');
    });

    it('spends points only with a live QR token, once', async () => {
      await expect(
        service.redeemInStore(STAFF, {
          code: 'qr-1',
          receiptNumber: 'B-1',
          receiptAmount: 200,
          points: 50,
        }),
      ).rejects.toThrow('live QR');

      const { code } = await service.issueQrToken('user-1');
      const r = await service.redeemInStore(STAFF, {
        code,
        receiptNumber: 'B-1',
        receiptAmount: 200,
        points: 50,
      });
      expect(r.balance).toBe(50);

      await expect(
        service.redeemInStore(STAFF, {
          code,
          receiptNumber: 'B-2',
          receiptAmount: 200,
          points: 10,
        }),
      ).rejects.toThrow('expired');
    });

    it('keeps the QR usable after a rejected attempt', async () => {
      const { code } = await service.issueQrToken('user-1');
      await expect(
        service.redeemInStore(STAFF, {
          code,
          receiptNumber: 'B-1',
          receiptAmount: 100,
          points: 51,
        }),
      ).rejects.toThrow('At most 50 points');
      await expect(
        service.redeemInStore(STAFF, {
          code,
          receiptNumber: 'B-1',
          receiptAmount: 1000,
          points: 101,
        }),
      ).rejects.toThrow('Not enough loyalty points');
      const ok = await service.redeemInStore(STAFF, {
        code,
        receiptNumber: 'B-1',
        receiptAmount: 100,
        points: 50,
      });
      expect(ok.balance).toBe(50);
    });

    it('limits points to the share of the receipt', async () => {
      const { code } = await service.issueQrToken('user-1');
      await expect(
        service.redeemInStore(STAFF, {
          code,
          receiptNumber: 'B-1',
          receiptAmount: 100,
          points: 51,
        }),
      ).rejects.toThrow('At most 50 points');
    });
  });

  describe('reverseTransaction', () => {
    it('writes the opposite entry once', async () => {
      const { transactionId } = await service.earnInStore(STAFF, {
        code: 'qr-1',
        receiptNumber: 'A-1',
        receiptAmount: 1000,
      });
      await service.reverseTransaction(ADMIN, transactionId, 'ошибка кассира');
      expect(balance()).toBe(100);
      expect(ledgerSum()).toBe(0);
      await expect(
        service.reverseTransaction(ADMIN, transactionId),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('cannot reverse a reversal', async () => {
      const { transactionId } = await service.earnInStore(STAFF, {
        code: 'qr-1',
        receiptNumber: 'A-1',
        receiptAmount: 1000,
      });
      const rev = await service.reverseTransaction(ADMIN, transactionId);
      await expect(
        service.reverseTransaction(ADMIN, rev.transactionId),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('claimFreeCoffee', () => {
    it('gives out the coffee, resets the card and logs who did it', async () => {
      const result = await service.claimFreeCoffee(STAFF, 'qr-1', 'M');
      expect(result.currentPunches).toBe(0);
      expect(db.txs[0]).toMatchObject({
        type: 'FREE_COFFEE',
        points: 0,
        staffId: 'staff-1',
      });
    });

    it('cannot be claimed twice', async () => {
      await service.claimFreeCoffee(STAFF, 'qr-1', 'M');
      await expect(
        service.claimFreeCoffee(STAFF, 'qr-1', 'M'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects an unknown QR code', async () => {
      await expect(
        service.claimFreeCoffee(STAFF, 'nope', 'M'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
