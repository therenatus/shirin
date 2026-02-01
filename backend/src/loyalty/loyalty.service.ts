import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CoffeeSize } from '@prisma/client';

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
  constructor(private prisma: PrismaService) {}

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
    // Get orders to build history
    const orders = await this.prisma.order.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        orderNumber: true,
        status: true,
        pointsUsed: true,
        pointsEarned: true,
        createdAt: true,
        completedAt: true,
      },
    });

    const transactions: LoyaltyTransaction[] = [];

    for (const order of orders) {
      // Points used in order
      if (order.pointsUsed > 0) {
        transactions.push({
          id: `${order.id}-used`,
          type: order.status === 'CANCELLED' ? 'refunded' : 'used',
          points: order.status === 'CANCELLED' ? order.pointsUsed : -order.pointsUsed,
          description:
            order.status === 'CANCELLED'
              ? `Возврат баллов за заказ ${order.orderNumber}`
              : `Списание за заказ ${order.orderNumber}`,
          orderId: order.id,
          orderNumber: order.orderNumber,
          createdAt: order.createdAt,
        });
      }

      // Points earned (only for completed orders)
      if (order.pointsEarned > 0 && order.status === 'DELIVERED') {
        transactions.push({
          id: `${order.id}-earned`,
          type: 'earned',
          points: order.pointsEarned,
          description: `Кешбэк за заказ ${order.orderNumber}`,
          orderId: order.id,
          orderNumber: order.orderNumber,
          createdAt: order.completedAt || order.createdAt,
        });
      }
    }

    // Sort by date descending
    transactions.sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );

    return transactions;
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
      });
    }

    // Fetch all cards again
    const allCards = await this.prisma.coffeePunchCard.findMany({
      where: { userId },
      orderBy: { size: 'asc' },
    });

    return allCards.map((card) => ({
      id: card.id,
      size: card.size,
      sizeName: this.getSizeName(card.size),
      currentPunches: card.currentPunches,
      maxPunches: card.maxPunches,
      isComplete: card.currentPunches >= card.maxPunches,
      freeItemClaimed: card.freeItemClaimed,
      createdAt: card.createdAt,
      completedAt: card.completedAt || undefined,
    }));
  }

  async addPunch(userId: string, size: CoffeeSize, count: number = 1): Promise<PunchCard> {
    // Get or create punch card for this size
    let card = await this.prisma.coffeePunchCard.findUnique({
      where: {
        userId_size: { userId, size },
      },
    });

    if (!card) {
      card = await this.prisma.coffeePunchCard.create({
        data: {
          userId,
          size,
          currentPunches: 0,
          maxPunches: 6,
        },
      });
    }

    // If card is already complete and claimed, reset it
    if (card.currentPunches >= card.maxPunches && card.freeItemClaimed) {
      card = await this.prisma.coffeePunchCard.update({
        where: { id: card.id },
        data: {
          currentPunches: 0,
          freeItemClaimed: false,
          completedAt: null,
        },
      });
    }

    // Add punches
    const newPunches = Math.min(card.currentPunches + count, card.maxPunches);
    const isComplete = newPunches >= card.maxPunches;

    card = await this.prisma.coffeePunchCard.update({
      where: { id: card.id },
      data: {
        currentPunches: newPunches,
        completedAt: isComplete && !card.completedAt ? new Date() : card.completedAt,
      },
    });

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

  async claimFreeCoffee(userId: string, size: CoffeeSize): Promise<PunchCard> {
    const card = await this.prisma.coffeePunchCard.findUnique({
      where: {
        userId_size: { userId, size },
      },
    });

    if (!card) {
      throw new NotFoundException('Punch card not found');
    }

    if (card.currentPunches < card.maxPunches) {
      throw new BadRequestException('Punch card is not complete');
    }

    if (card.freeItemClaimed) {
      throw new BadRequestException('Free coffee already claimed');
    }

    const updatedCard = await this.prisma.coffeePunchCard.update({
      where: { id: card.id },
      data: {
        freeItemClaimed: true,
      },
    });

    return {
      id: updatedCard.id,
      size: updatedCard.size,
      sizeName: this.getSizeName(updatedCard.size),
      currentPunches: updatedCard.currentPunches,
      maxPunches: updatedCard.maxPunches,
      isComplete: updatedCard.currentPunches >= updatedCard.maxPunches,
      freeItemClaimed: updatedCard.freeItemClaimed,
      createdAt: updatedCard.createdAt,
      completedAt: updatedCard.completedAt || undefined,
    };
  }

  async resetPunchCard(userId: string, size: CoffeeSize): Promise<PunchCard> {
    const card = await this.prisma.coffeePunchCard.findUnique({
      where: {
        userId_size: { userId, size },
      },
    });

    if (!card) {
      throw new NotFoundException('Punch card not found');
    }

    const updatedCard = await this.prisma.coffeePunchCard.update({
      where: { id: card.id },
      data: {
        currentPunches: 0,
        freeItemClaimed: false,
        completedAt: null,
      },
    });

    return {
      id: updatedCard.id,
      size: updatedCard.size,
      sizeName: this.getSizeName(updatedCard.size),
      currentPunches: updatedCard.currentPunches,
      maxPunches: updatedCard.maxPunches,
      isComplete: false,
      freeItemClaimed: false,
      createdAt: updatedCard.createdAt,
      completedAt: undefined,
    };
  }
}
