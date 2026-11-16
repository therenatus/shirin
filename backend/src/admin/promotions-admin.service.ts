import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePromotionDto, UpdatePromotionDto } from './dto/promotion.dto';

/**
 * Promotions are banners in the app (title, text, image, dates). They do not
 * change order prices: discounts are not applied automatically.
 */
@Injectable()
export class PromotionsAdminService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    const rows = await this.prisma.promotion.findMany({
      orderBy: [{ isActive: 'desc' }, { endDate: 'desc' }],
    });
    const now = new Date();
    return rows.map((p) => ({
      ...p,
      minOrderAmount: p.minOrderAmount ? Number(p.minOrderAmount) : null,
      // What the customer sees right now
      isLive: p.isActive && p.startDate <= now && p.endDate >= now,
    }));
  }

  private toData(
    dto: UpdatePromotionDto,
  ): Prisma.PromotionUncheckedUpdateInput {
    return {
      // Base fields mirror Russian, the primary language
      ...(dto.titleRu !== undefined && {
        title: dto.titleRu,
        titleRu: dto.titleRu,
      }),
      ...(dto.descriptionRu !== undefined && {
        description: dto.descriptionRu,
        descriptionRu: dto.descriptionRu,
      }),
      titleKy: dto.titleKy,
      descriptionKy: dto.descriptionKy,
      image: dto.image,
      type: dto.type,
      discountPercent: dto.discountPercent,
      cashbackPercent: dto.cashbackPercent,
      minOrderAmount: dto.minOrderAmount,
      productIds: dto.productIds,
      startDate: dto.startDate ? new Date(dto.startDate) : undefined,
      endDate: dto.endDate ? new Date(dto.endDate) : undefined,
      isActive: dto.isActive,
      sortOrder: dto.sortOrder,
    };
  }

  private checkDates(start?: string | Date, end?: string | Date) {
    if (start && end && new Date(end) <= new Date(start)) {
      throw new BadRequestException('End date must be after start date');
    }
  }

  async create(dto: CreatePromotionDto) {
    this.checkDates(dto.startDate, dto.endDate);
    return this.prisma.promotion.create({
      data: this.toData(dto) as Prisma.PromotionUncheckedCreateInput,
    });
  }

  async update(id: string, dto: UpdatePromotionDto) {
    const current = await this.prisma.promotion.findUnique({ where: { id } });
    if (!current) throw new NotFoundException('Promotion not found');
    this.checkDates(
      dto.startDate ?? current.startDate,
      dto.endDate ?? current.endDate,
    );
    return this.prisma.promotion.update({
      where: { id },
      data: this.toData(dto),
    });
  }

  async remove(id: string) {
    const { count } = await this.prisma.promotion.deleteMany({ where: { id } });
    if (count === 0) throw new NotFoundException('Promotion not found');
    return { success: true };
  }
}
