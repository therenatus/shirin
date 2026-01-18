import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface LoyaltyTransaction {
  id: string;
  type: 'earned' | 'used' | 'refunded';
  points: number;
  description: string;
  orderId?: string;
  orderNumber?: string;
  createdAt: Date;
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

    return {
      points: user.loyaltyPoints,
      qrCode: user.qrCode,
    };
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
}
