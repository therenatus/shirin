import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAddressDto, UpdateAddressDto } from './dto/create-address.dto';

@Injectable()
export class AddressesService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: string) {
    const addresses = await this.prisma.address.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });

    return addresses.map((addr) => ({
      id: addr.id,
      name: addr.name,
      street: addr.street,
      apartment: addr.apartment,
      entrance: addr.entrance,
      floor: addr.floor,
      intercom: addr.intercom,
      latitude: addr.latitude ? Number(addr.latitude) : null,
      longitude: addr.longitude ? Number(addr.longitude) : null,
      isDefault: addr.isDefault,
    }));
  }

  async findOne(userId: string, id: string) {
    const address = await this.prisma.address.findUnique({
      where: { id },
    });

    if (!address) {
      throw new NotFoundException('Address not found');
    }

    if (address.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return {
      id: address.id,
      name: address.name,
      street: address.street,
      apartment: address.apartment,
      entrance: address.entrance,
      floor: address.floor,
      intercom: address.intercom,
      latitude: address.latitude ? Number(address.latitude) : null,
      longitude: address.longitude ? Number(address.longitude) : null,
      isDefault: address.isDefault,
    };
  }

  async create(userId: string, dto: CreateAddressDto) {
    // If this is the first address or marked as default, reset other defaults
    if (dto.isDefault) {
      await this.prisma.address.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false },
      });
    }

    // Check if this is the first address
    const count = await this.prisma.address.count({ where: { userId } });
    const isDefault = dto.isDefault || count === 0;

    const address = await this.prisma.address.create({
      data: {
        name: dto.name,
        street: dto.street,
        apartment: dto.apartment,
        entrance: dto.entrance,
        floor: dto.floor,
        intercom: dto.intercom,
        latitude: dto.latitude,
        longitude: dto.longitude,
        isDefault,
        userId,
      },
    });

    return {
      id: address.id,
      name: address.name,
      street: address.street,
      apartment: address.apartment,
      entrance: address.entrance,
      floor: address.floor,
      intercom: address.intercom,
      latitude: address.latitude ? Number(address.latitude) : null,
      longitude: address.longitude ? Number(address.longitude) : null,
      isDefault: address.isDefault,
    };
  }

  async update(userId: string, id: string, dto: UpdateAddressDto) {
    const address = await this.prisma.address.findUnique({
      where: { id },
    });

    if (!address) {
      throw new NotFoundException('Address not found');
    }

    if (address.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    const updated = await this.prisma.address.update({
      where: { id },
      data: {
        name: dto.name,
        street: dto.street,
        apartment: dto.apartment,
        entrance: dto.entrance,
        floor: dto.floor,
        intercom: dto.intercom,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
    });

    return {
      id: updated.id,
      name: updated.name,
      street: updated.street,
      apartment: updated.apartment,
      entrance: updated.entrance,
      floor: updated.floor,
      intercom: updated.intercom,
      latitude: updated.latitude ? Number(updated.latitude) : null,
      longitude: updated.longitude ? Number(updated.longitude) : null,
      isDefault: updated.isDefault,
    };
  }

  async delete(userId: string, id: string) {
    const address = await this.prisma.address.findUnique({
      where: { id },
    });

    if (!address) {
      throw new NotFoundException('Address not found');
    }

    if (address.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    await this.prisma.address.delete({ where: { id } });

    // If deleted address was default, make another one default
    if (address.isDefault) {
      const remaining = await this.prisma.address.findFirst({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      });

      if (remaining) {
        await this.prisma.address.update({
          where: { id: remaining.id },
          data: { isDefault: true },
        });
      }
    }

    return { success: true };
  }

  async setDefault(userId: string, id: string) {
    const address = await this.prisma.address.findUnique({
      where: { id },
    });

    if (!address) {
      throw new NotFoundException('Address not found');
    }

    if (address.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    // Reset all defaults
    await this.prisma.address.updateMany({
      where: { userId, isDefault: true },
      data: { isDefault: false },
    });

    // Set this one as default
    await this.prisma.address.update({
      where: { id },
      data: { isDefault: true },
    });

    return { success: true };
  }
}
