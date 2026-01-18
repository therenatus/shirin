import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

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
}
