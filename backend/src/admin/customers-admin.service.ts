import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { OrderStatus, Prisma, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CustomersAdminService {
  constructor(private prisma: PrismaService) {}

  async list(query: {
    search?: string;
    page?: number;
    limit?: number;
    blocked?: boolean;
  }) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const where: Prisma.UserWhereInput = {
      role: UserRole.CLIENT,
      // Deleted accounts keep a placeholder phone and are not customers
      NOT: { phone: { startsWith: 'deleted:' } },
    };
    if (query.blocked !== undefined) where.isActive = !query.blocked;
    const search = query.search?.trim();
    if (search) {
      const digits = search.replace(/\D/g, '');
      where.OR = [
        ...(digits ? [{ phone: { contains: digits } }] : []),
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          phone: true,
          firstName: true,
          lastName: true,
          loyaltyPoints: true,
          isActive: true,
          createdAt: true,
          lastLoginAt: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    // Orders and money per customer on this page (cancelled orders excluded)
    const stats = await this.prisma.order.groupBy({
      by: ['userId'],
      where: {
        userId: { in: users.map((u) => u.id) },
        status: { not: OrderStatus.CANCELLED },
      },
      _count: { _all: true },
      _sum: { total: true },
      _max: { createdAt: true },
    });
    const byUser = new Map(stats.map((s) => [s.userId, s]));

    return {
      data: users.map((u) => {
        const s = byUser.get(u.id);
        return {
          ...u,
          ordersCount: s?._count._all ?? 0,
          totalSpent: Number(s?._sum.total ?? 0),
          lastOrderAt: s?._max.createdAt ?? null,
        };
      }),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  /** Blocking ends all sessions at once: tokens are checked against isActive. */
  async setBlocked(id: string, blocked: boolean) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: { role: true, phone: true },
    });
    if (!user || user.phone.startsWith('deleted:')) {
      throw new NotFoundException('Customer not found');
    }
    if (user.role !== UserRole.CLIENT) {
      throw new BadRequestException('Employees are managed on the staff page');
    }
    return this.prisma.user.update({
      where: { id },
      data: { isActive: !blocked, ...(blocked && { fcmToken: null }) },
      select: { id: true, isActive: true },
    });
  }
}
