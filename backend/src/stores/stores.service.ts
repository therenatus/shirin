import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class StoresService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    const stores = await this.prisma.store.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });

    return stores.map((store) => ({
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
    }));
  }

  async findOne(id: string) {
    const store = await this.prisma.store.findUnique({
      where: { id },
    });

    if (!store) {
      throw new NotFoundException('Store not found');
    }

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
    };
  }
}
