import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
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
  constructor(private prisma: PrismaService) {}

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
