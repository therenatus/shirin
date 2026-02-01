import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto, UpdateProductDto } from './dto/create-product.dto';
import { QueryProductsDto, ProductSortBy } from './dto/query-products.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async findAll(query: QueryProductsDto) {
    const {
      categoryId,
      search,
      sortBy,
      page = 1,
      limit = 20,
      isNew,
      isBestseller,
      hasDiscount,
      minPrice,
      maxPrice,
    } = query;

    const where: Prisma.ProductWhereInput = {
      isAvailable: true,
    };

    if (categoryId) {
      where.categoryId = categoryId;
    }

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { nameRu: { contains: search, mode: 'insensitive' } },
        { nameKy: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (isNew !== undefined) {
      where.isNew = isNew;
    }

    if (isBestseller !== undefined) {
      where.isBestseller = isBestseller;
    }

    if (hasDiscount) {
      where.discountPrice = { not: null };
    }

    // Price range filters
    if (minPrice !== undefined || maxPrice !== undefined) {
      where.price = {};
      if (minPrice !== undefined) {
        where.price.gte = minPrice;
      }
      if (maxPrice !== undefined) {
        where.price.lte = maxPrice;
      }
    }

    let orderBy: Prisma.ProductOrderByWithRelationInput = { sortOrder: 'asc' };

    switch (sortBy) {
      case ProductSortBy.PRICE_ASC:
        orderBy = { price: 'asc' };
        break;
      case ProductSortBy.PRICE_DESC:
        orderBy = { price: 'desc' };
        break;
      case ProductSortBy.NAME_ASC:
        orderBy = { name: 'asc' };
        break;
      case ProductSortBy.NAME_DESC:
        orderBy = { name: 'desc' };
        break;
      case ProductSortBy.NEWEST:
        orderBy = { createdAt: 'desc' };
        break;
      case ProductSortBy.POPULAR:
        orderBy = { sortOrder: 'asc' }; // Use sortOrder as popularity indicator (can be updated by admin based on sales)
        break;
    }

    const skip = (page - 1) * limit;

    const [products, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        orderBy,
        skip,
        take: limit,
        include: {
          category: {
            select: {
              id: true,
              name: true,
              nameRu: true,
              nameKy: true,
            },
          },
        },
      }),
      this.prisma.product.count({ where }),
    ]);

    return {
      data: products,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOne(id: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: {
        category: {
          select: {
            id: true,
            name: true,
            nameRu: true,
            nameKy: true,
          },
        },
        reviews: {
          include: {
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                avatar: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        _count: {
          select: {
            reviews: true,
            favorites: true,
          },
        },
      },
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    // Calculate average rating
    const avgRating = await this.prisma.review.aggregate({
      where: { productId: id },
      _avg: { rating: true },
    });

    return {
      ...product,
      averageRating: avgRating._avg.rating || 0,
    };
  }

  async getCategories() {
    const categories = await this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: {
        _count: {
          select: {
            products: {
              where: { isAvailable: true },
            },
          },
        },
      },
    });

    return categories.map((cat) => ({
      id: cat.id,
      name: cat.name,
      nameRu: cat.nameRu,
      nameKy: cat.nameKy,
      description: cat.description,
      image: cat.image,
      icon: cat.icon,
      productCount: cat._count.products,
    }));
  }

  async getFavorites(userId: string) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId },
      include: {
        product: {
          include: {
            category: {
              select: {
                id: true,
                name: true,
                nameRu: true,
                nameKy: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return favorites.map((fav) => fav.product);
  }

  async toggleFavorite(userId: string, productId: string) {
    // Check if product exists
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    const existing = await this.prisma.favorite.findUnique({
      where: {
        userId_productId: { userId, productId },
      },
    });

    if (existing) {
      await this.prisma.favorite.delete({
        where: { id: existing.id },
      });
      return { isFavorite: false };
    } else {
      await this.prisma.favorite.create({
        data: { userId, productId },
      });
      return { isFavorite: true };
    }
  }

  async checkFavorite(userId: string, productId: string) {
    const favorite = await this.prisma.favorite.findUnique({
      where: {
        userId_productId: { userId, productId },
      },
    });

    return { isFavorite: !!favorite };
  }

  // Admin methods
  async create(dto: CreateProductDto) {
    return this.prisma.product.create({
      data: {
        name: dto.name,
        nameKy: dto.nameKy,
        nameRu: dto.nameRu,
        description: dto.description,
        descriptionKy: dto.descriptionKy,
        descriptionRu: dto.descriptionRu,
        price: dto.price,
        discountPrice: dto.discountPrice,
        images: dto.images || [],
        ingredients: dto.ingredients,
        weight: dto.weight,
        calories: dto.calories,
        isAvailable: dto.isAvailable ?? true,
        isNew: dto.isNew ?? false,
        isBestseller: dto.isBestseller ?? false,
        sortOrder: dto.sortOrder ?? 0,
        categoryId: dto.categoryId,
      },
      include: {
        category: true,
      },
    });
  }

  async update(id: string, dto: UpdateProductDto) {
    const product = await this.prisma.product.findUnique({ where: { id } });
    if (!product) {
      throw new NotFoundException('Product not found');
    }

    return this.prisma.product.update({
      where: { id },
      data: dto,
      include: {
        category: true,
      },
    });
  }

  async delete(id: string) {
    const product = await this.prisma.product.findUnique({ where: { id } });
    if (!product) {
      throw new NotFoundException('Product not found');
    }

    await this.prisma.product.delete({ where: { id } });
    return { success: true };
  }
}
