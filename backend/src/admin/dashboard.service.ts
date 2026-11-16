import { Injectable } from '@nestjs/common';
import { OrderStatus, PaymentStatus, Prisma, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/** Business days are counted in Bishkek time, like order numbers. */
const TZ = 'Asia/Bishkek';
const TZ_OFFSET_HOURS = 6; // UTC+6, no daylight saving

/** Start of the business day containing `d`, as a UTC instant. */
export function startOfBusinessDay(d: Date): Date {
  const shifted = new Date(d.getTime() + TZ_OFFSET_HOURS * 3600_000);
  shifted.setUTCHours(0, 0, 0, 0);
  return new Date(shifted.getTime() - TZ_OFFSET_HOURS * 3600_000);
}

const NOT_CANCELLED: Prisma.OrderWhereInput = {
  status: { not: OrderStatus.CANCELLED },
};

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getStats(days: number, now = new Date()) {
    const today = startOfBusinessDay(now);
    const from = new Date(today.getTime() - (days - 1) * 86400_000);
    const monthAgo = new Date(now.getTime() - 30 * 86400_000);

    const [
      todayAgg,
      todayOrders,
      pending,
      awaitingPayment,
      refundsPending,
      newCustomersToday,
      activeCustomers,
      chartRows,
      top,
      recent,
      loyalty,
    ] = await Promise.all([
      this.prisma.order.aggregate({
        where: { ...NOT_CANCELLED, createdAt: { gte: today } },
        _sum: { total: true },
        _count: { _all: true },
      }),
      this.prisma.order.count({ where: { createdAt: { gte: today } } }),
      this.prisma.order.count({
        where: {
          status: OrderStatus.PENDING,
          paymentStatus: { not: PaymentStatus.PENDING },
        },
      }),
      this.prisma.order.count({
        where: {
          paymentStatus: PaymentStatus.PENDING,
          status: OrderStatus.PENDING,
        },
      }),
      this.prisma.order.count({
        where: { paymentStatus: PaymentStatus.REFUND_PENDING },
      }),
      this.prisma.user.count({
        where: { role: UserRole.CLIENT, createdAt: { gte: today } },
      }),
      this.prisma.order
        .groupBy({
          by: ['userId'],
          where: { ...NOT_CANCELLED, createdAt: { gte: monthAgo } },
        })
        .then((rows) => rows.length),
      this.prisma.$queryRaw<
        { day: Date; amount: Prisma.Decimal | null; orders: bigint }[]
      >`
        SELECT date_trunc('day', "createdAt" AT TIME ZONE 'UTC' AT TIME ZONE ${TZ}) AS day,
               SUM("total") AS amount,
               COUNT(*) AS orders
        FROM "orders"
        WHERE "status" <> 'CANCELLED' AND "createdAt" >= ${from}
        GROUP BY 1
        ORDER BY 1`,
      this.prisma.orderItem.groupBy({
        by: ['productId'],
        where: { order: { ...NOT_CANCELLED, createdAt: { gte: monthAgo } } },
        _sum: { quantity: true, total: true },
        orderBy: { _sum: { quantity: 'desc' } },
        take: 5,
      }),
      this.prisma.order.findMany({
        orderBy: { createdAt: 'desc' },
        take: 6,
        select: {
          id: true,
          orderNumber: true,
          status: true,
          paymentStatus: true,
          total: true,
          deliveryType: true,
          createdAt: true,
          store: { select: { name: true } },
          user: { select: { phone: true, firstName: true, lastName: true } },
        },
      }),
      this.prisma.loyaltyTransaction.groupBy({
        by: ['type'],
        where: {
          createdAt: { gte: monthAgo },
          type: { in: ['EARN', 'REDEEM'] },
        },
        _sum: { points: true },
      }),
    ]);

    // Fill days without orders with zeros
    const byDay = new Map(
      chartRows.map((r) => [
        r.day.toISOString().slice(0, 10),
        { amount: Number(r.amount ?? 0), orders: Number(r.orders) },
      ]),
    );
    const salesChart = Array.from({ length: days }, (_, i) => {
      const dayStart = new Date(from.getTime() + i * 86400_000);
      // Local calendar date of this business day
      const date = new Date(dayStart.getTime() + TZ_OFFSET_HOURS * 3600_000)
        .toISOString()
        .slice(0, 10);
      return { date, ...(byDay.get(date) ?? { amount: 0, orders: 0 }) };
    });

    const products = await this.prisma.product.findMany({
      where: { id: { in: top.map((t) => t.productId) } },
      select: { id: true, name: true, nameRu: true },
    });
    const names = new Map(products.map((p) => [p.id, p.nameRu || p.name]));

    const paidOrders = todayAgg._count._all;
    const revenue = Number(todayAgg._sum.total ?? 0);
    const points = (t: string) =>
      Math.abs(loyalty.find((l) => l.type === t)?._sum.points ?? 0);

    return {
      today: {
        revenue,
        orders: todayOrders,
        averageCheck: paidOrders ? Math.round(revenue / paidOrders) : 0,
        newCustomers: newCustomersToday,
      },
      queue: { pending, awaitingPayment, refundsPending },
      activeCustomers30d: activeCustomers,
      salesChart,
      topProducts: top.map((t) => ({
        productId: t.productId,
        name: names.get(t.productId) ?? '—',
        quantity: t._sum.quantity ?? 0,
        revenue: Number(t._sum.total ?? 0),
      })),
      loyalty30d: { earned: points('EARN'), redeemed: points('REDEEM') },
      recentOrders: recent.map((o) => ({
        ...o,
        total: Number(o.total),
        customer:
          [o.user.firstName, o.user.lastName].filter(Boolean).join(' ') ||
          o.user.phone,
        user: undefined,
      })),
    };
  }
}
