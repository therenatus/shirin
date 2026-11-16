import { Injectable, NotFoundException } from '@nestjs/common';
import { Store } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateStoreDto, UpdateStoreDto } from './dto/create-store.dto';

@Injectable()
export class StoresService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    const stores = await this.prisma.store.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });

    return stores.map((store) => this.formatStore(store));
  }

  async findOne(id: string) {
    const store = await this.prisma.store.findUnique({
      where: { id },
    });

    if (!store) {
      throw new NotFoundException('Store not found');
    }

    return this.formatStore(store);
  }

  async create(dto: CreateStoreDto) {
    const store = await this.prisma.store.create({ data: dto });
    return this.formatStore(store);
  }

  async update(id: string, dto: UpdateStoreDto) {
    await this.findOne(id);
    const store = await this.prisma.store.update({ where: { id }, data: dto });
    return this.formatStore(store);
  }

  /** Soft delete: stores are referenced by past orders. */
  async remove(id: string) {
    await this.findOne(id);
    await this.prisma.store.update({
      where: { id },
      data: { isActive: false },
    });
    return { success: true };
  }

  private formatStore(store: Store) {
    return {
      id: store.id,
      name: store.name,
      nameRu: store.nameRu,
      nameKy: store.nameKy,
      address: store.address,
      addressRu: store.addressRu,
      addressKy: store.addressKy,
      latitude: Number(store.latitude),
      longitude: Number(store.longitude),
      phone: store.phone,
      workHours: store.workHours,
      image: store.image,
      isActive: store.isActive,
    };
  }
}
