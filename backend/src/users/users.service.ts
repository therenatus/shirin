import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  LoyaltyTxSource,
  LoyaltyTxType,
  OrderStatus,
  Prisma,
  UserRole,
} from '@prisma/client';
import { LoyaltyService } from '../loyalty/loyalty.service';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryStaffDto, UpdateUserRoleDto } from './dto/staff.dto';

const STAFF_SELECT = {
  id: true,
  phone: true,
  firstName: true,
  lastName: true,
  role: true,
  isActive: true,
  store: { select: { id: true, name: true } },
} satisfies Prisma.UserSelect;

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService,
    private loyaltyService: LoyaltyService,
  ) {}

  /**
   * Deletes the customer's account (App Store requirement).
   *
   * Personal data is erased; orders stay, without a link to a person, as
   * they are needed for accounting. The account is deactivated, which ends
   * every session: access tokens are checked against isActive on each
   * request and refresh is refused. The phone is freed, so the person can
   * sign up again later as a new customer.
   */
  async deleteAccount(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true, loyaltyPoints: true, isActive: true },
    });
    if (!user || !user.isActive) {
      throw new NotFoundException('User not found');
    }
    if (user.role !== UserRole.CLIENT) {
      throw new ForbiddenException(
        'Employee accounts are removed by an administrator',
      );
    }

    const active = await this.prisma.order.count({
      where: {
        userId,
        status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
      },
    });
    if (active > 0) {
      throw new BadRequestException(
        'You have active orders: wait for them to complete or cancel them',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      if (user.loyaltyPoints > 0) {
        await this.loyaltyService.applyPoints(tx, {
          userId,
          type: LoyaltyTxType.ADJUST,
          source: LoyaltyTxSource.MANUAL,
          points: -user.loyaltyPoints,
          description: 'Аккаунт удалён',
        });
      }

      await tx.address.deleteMany({ where: { userId } });
      await tx.favorite.deleteMany({ where: { userId } });
      await tx.notification.deleteMany({ where: { userId } });
      await tx.chatMessage.deleteMany({ where: { userId } });
      await tx.coffeePunchCard.deleteMany({ where: { userId } });
      await tx.raffleEntry.deleteMany({ where: { userId } });

      await tx.user.update({
        where: { id: userId },
        data: {
          phone: `deleted:${userId}`,
          firstName: null,
          lastName: null,
          email: null,
          avatar: null,
          birthDate: null,
          fcmToken: null,
          password: null,
          externalId: null,
          qrCode: randomUUID(),
          isActive: false,
        },
      });
    });

    return { success: true };
  }

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        phone: true,
        firstName: true,
        lastName: true,
        email: true,
        avatar: true,
        birthDate: true,
        loyaltyPoints: true,
        qrCode: true,
        createdAt: true,
        role: true,
        store: { select: { id: true, name: true } },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async updateProfile(userId: string, dto: UpdateUserDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        email: dto.email,
        birthDate: dto.birthDate ? new Date(dto.birthDate) : undefined,
      },
      select: {
        id: true,
        phone: true,
        firstName: true,
        lastName: true,
        email: true,
        avatar: true,
        birthDate: true,
        loyaltyPoints: true,
        qrCode: true,
      },
    });
  }

  async getQRCode(userId: string) {
    const user = await this.findById(userId);

    return {
      qrCode: user.qrCode,
      qrCodeImage: null, // TODO: Generate QR code image
    };
  }

  async updateFCMToken(userId: string, fcmToken: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });

    return { success: true };
  }

  // ==================== STAFF (ADMIN) ====================

  async findStaff(query: QueryStaffDto) {
    const where: Prisma.UserWhereInput = {};
    if (query.staffOnly !== false) {
      where.role = { not: UserRole.CLIENT };
    }
    const search = query.search?.trim();
    if (search) {
      where.OR = [
        { phone: { contains: search.replace(/[^\d+]/g, '') || search } },
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
      ];
    }

    return this.prisma.user.findMany({
      where,
      select: STAFF_SELECT,
      orderBy: [{ role: 'asc' }, { phone: 'asc' }],
      take: 50,
    });
  }

  async updateRole(actorId: string, userId: string, dto: UpdateUserRoleDto) {
    if (actorId === userId && dto.role !== UserRole.ADMIN) {
      // Prevents an admin from locking themselves out
      throw new BadRequestException('You cannot remove your own admin role');
    }

    let storeId: string | null = null;
    if (dto.role === UserRole.STORE_STAFF) {
      if (!dto.storeId) {
        throw new BadRequestException('Store is required for store staff');
      }
      const store = await this.prisma.store.findFirst({
        where: { id: dto.storeId, isActive: true },
        select: { id: true },
      });
      if (!store) {
        throw new BadRequestException('Store not found');
      }
      storeId = store.id;
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: { role: dto.role, storeId },
      select: STAFF_SELECT,
    });
  }
}
