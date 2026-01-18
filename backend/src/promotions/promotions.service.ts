import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PromotionsService {
  constructor(private prisma: PrismaService) {}

  async findAllPromotions() {
    const now = new Date();

    const promotions = await this.prisma.promotion.findMany({
      where: {
        isActive: true,
        startDate: { lte: now },
        endDate: { gte: now },
      },
      orderBy: { sortOrder: 'asc' },
    });

    return promotions.map((promo) => ({
      id: promo.id,
      title: promo.title,
      titleRu: promo.titleRu,
      titleKy: promo.titleKy,
      description: promo.description,
      descriptionRu: promo.descriptionRu,
      descriptionKy: promo.descriptionKy,
      image: promo.image,
      type: promo.type,
      discountPercent: promo.discountPercent,
      cashbackPercent: promo.cashbackPercent,
      minOrderAmount: promo.minOrderAmount ? Number(promo.minOrderAmount) : null,
      startDate: promo.startDate,
      endDate: promo.endDate,
    }));
  }

  async findOnePromotion(id: string) {
    const promotion = await this.prisma.promotion.findUnique({
      where: { id },
    });

    if (!promotion) {
      throw new NotFoundException('Promotion not found');
    }

    // Get related products if any
    let products: {
      id: string;
      name: string;
      nameRu: string | null;
      nameKy: string | null;
      price: number;
      discountPrice: number | null;
      images: string[];
    }[] = [];

    if (promotion.productIds && promotion.productIds.length > 0) {
      const rawProducts = await this.prisma.product.findMany({
        where: {
          id: { in: promotion.productIds },
          isAvailable: true,
        },
        select: {
          id: true,
          name: true,
          nameRu: true,
          nameKy: true,
          price: true,
          discountPrice: true,
          images: true,
        },
      });
      products = rawProducts.map((p) => ({
        id: p.id,
        name: p.name,
        nameRu: p.nameRu,
        nameKy: p.nameKy,
        price: Number(p.price),
        discountPrice: p.discountPrice ? Number(p.discountPrice) : null,
        images: p.images,
      }));
    }

    return {
      id: promotion.id,
      title: promotion.title,
      titleRu: promotion.titleRu,
      titleKy: promotion.titleKy,
      description: promotion.description,
      descriptionRu: promotion.descriptionRu,
      descriptionKy: promotion.descriptionKy,
      image: promotion.image,
      type: promotion.type,
      discountPercent: promotion.discountPercent,
      cashbackPercent: promotion.cashbackPercent,
      minOrderAmount: promotion.minOrderAmount
        ? Number(promotion.minOrderAmount)
        : null,
      startDate: promotion.startDate,
      endDate: promotion.endDate,
      products,
    };
  }

  async findAllRaffles() {
    const now = new Date();

    const raffles = await this.prisma.raffle.findMany({
      where: {
        isActive: true,
        startDate: { lte: now },
        endDate: { gte: now },
      },
      orderBy: { drawDate: 'asc' },
      include: {
        _count: {
          select: { entries: true },
        },
      },
    });

    return raffles.map((raffle) => ({
      id: raffle.id,
      title: raffle.title,
      titleRu: raffle.titleRu,
      titleKy: raffle.titleKy,
      description: raffle.description,
      descriptionRu: raffle.descriptionRu,
      descriptionKy: raffle.descriptionKy,
      image: raffle.image,
      prize: raffle.prize,
      minPointsRequired: raffle.minPointsRequired,
      minPurchaseAmount: raffle.minPurchaseAmount
        ? Number(raffle.minPurchaseAmount)
        : null,
      startDate: raffle.startDate,
      endDate: raffle.endDate,
      drawDate: raffle.drawDate,
      entriesCount: raffle._count.entries,
    }));
  }

  async findOneRaffle(id: string, userId?: string) {
    const raffle = await this.prisma.raffle.findUnique({
      where: { id },
      include: {
        _count: {
          select: { entries: true },
        },
      },
    });

    if (!raffle) {
      throw new NotFoundException('Raffle not found');
    }

    let isEntered = false;
    if (userId) {
      const entry = await this.prisma.raffleEntry.findUnique({
        where: {
          userId_raffleId: { userId, raffleId: id },
        },
      });
      isEntered = !!entry;
    }

    return {
      id: raffle.id,
      title: raffle.title,
      titleRu: raffle.titleRu,
      titleKy: raffle.titleKy,
      description: raffle.description,
      descriptionRu: raffle.descriptionRu,
      descriptionKy: raffle.descriptionKy,
      image: raffle.image,
      prize: raffle.prize,
      minPointsRequired: raffle.minPointsRequired,
      minPurchaseAmount: raffle.minPurchaseAmount
        ? Number(raffle.minPurchaseAmount)
        : null,
      startDate: raffle.startDate,
      endDate: raffle.endDate,
      drawDate: raffle.drawDate,
      entriesCount: raffle._count.entries,
      isEntered,
    };
  }

  async enterRaffle(userId: string, raffleId: string) {
    const raffle = await this.prisma.raffle.findUnique({
      where: { id: raffleId },
    });

    if (!raffle) {
      throw new NotFoundException('Raffle not found');
    }

    const now = new Date();
    if (now < raffle.startDate || now > raffle.endDate) {
      throw new BadRequestException('Raffle is not active');
    }

    // Check if already entered
    const existingEntry = await this.prisma.raffleEntry.findUnique({
      where: {
        userId_raffleId: { userId, raffleId },
      },
    });

    if (existingEntry) {
      throw new BadRequestException('Already entered this raffle');
    }

    // Check requirements
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (raffle.minPointsRequired && user!.loyaltyPoints < raffle.minPointsRequired) {
      throw new BadRequestException(
        `Requires at least ${raffle.minPointsRequired} loyalty points`,
      );
    }

    if (raffle.minPurchaseAmount) {
      // Check user's total purchases
      const totalPurchases = await this.prisma.order.aggregate({
        where: {
          userId,
          status: 'DELIVERED',
        },
        _sum: {
          total: true,
        },
      });

      const purchaseAmount = totalPurchases._sum.total || 0;
      if (Number(purchaseAmount) < Number(raffle.minPurchaseAmount)) {
        throw new BadRequestException(
          `Requires at least ${raffle.minPurchaseAmount} som in purchases`,
        );
      }
    }

    // Create entry
    await this.prisma.raffleEntry.create({
      data: {
        userId,
        raffleId,
      },
    });

    return { success: true, message: 'Successfully entered the raffle' };
  }
}
