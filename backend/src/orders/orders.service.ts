import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto, DeliveryType } from './dto/create-order.dto';
import { OrderStatus, Prisma, CoffeeSize } from '@prisma/client';
import { LoyaltyService } from '../loyalty/loyalty.service';

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private loyaltyService: LoyaltyService,
  ) {}

  async create(userId: string, dto: CreateOrderDto) {
    // Validate delivery type requirements
    if (dto.deliveryType === DeliveryType.DELIVERY && !dto.addressId) {
      throw new BadRequestException('Address is required for delivery');
    }

    if (dto.deliveryType === DeliveryType.PICKUP && !dto.storeId) {
      throw new BadRequestException('Store is required for pickup');
    }

    // Get user
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Validate products and calculate subtotal
    const productIds = dto.items.map((item) => item.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds }, isAvailable: true },
    });

    if (products.length !== productIds.length) {
      throw new BadRequestException('Some products are not available');
    }

    const productMap = new Map(products.map((p) => [p.id, p]));

    let subtotal = new Prisma.Decimal(0);
    const orderItems: {
      productId: string;
      quantity: number;
      price: Prisma.Decimal;
      total: Prisma.Decimal;
    }[] = [];

    for (const item of dto.items) {
      const product = productMap.get(item.productId)!;
      const price = product.discountPrice || product.price;
      const itemTotal = price.mul(item.quantity);

      orderItems.push({
        productId: item.productId,
        quantity: item.quantity,
        price,
        total: itemTotal,
      });

      subtotal = subtotal.add(itemTotal);
    }

    // Get settings
    const settings = await this.getSettings();

    // Calculate delivery fee
    let deliveryFee = new Prisma.Decimal(0);
    if (dto.deliveryType === DeliveryType.DELIVERY) {
      if (subtotal.lt(settings.freeDeliveryMinAmount)) {
        deliveryFee = new Prisma.Decimal(settings.deliveryFee);
      }
    }

    // Calculate points discount
    let pointsToUse = dto.pointsToUse || 0;
    let pointsDiscount = new Prisma.Decimal(0);

    if (pointsToUse > 0) {
      if (pointsToUse > user.loyaltyPoints) {
        throw new BadRequestException('Not enough loyalty points');
      }

      // 1 point = 1 som
      const maxPointsDiscount = subtotal.mul(settings.maxPointsUsePercent / 100);
      const requestedDiscount = new Prisma.Decimal(pointsToUse);

      if (requestedDiscount.gt(maxPointsDiscount)) {
        pointsToUse = maxPointsDiscount.toNumber();
      }

      pointsDiscount = new Prisma.Decimal(pointsToUse);
    }

    // Calculate total
    const total = subtotal.add(deliveryFee).sub(pointsDiscount);

    // Calculate points to earn (based on subtotal, not total)
    const pointsEarned = Math.floor(
      subtotal.toNumber() * (settings.cashbackPercent / 100),
    );

    // Generate order number
    const orderNumber = await this.generateOrderNumber();

    // Create order in transaction
    const order = await this.prisma.$transaction(async (tx) => {
      // Deduct points if used
      if (pointsToUse > 0) {
        await tx.user.update({
          where: { id: userId },
          data: { loyaltyPoints: { decrement: pointsToUse } },
        });
      }

      // Create order
      return tx.order.create({
        data: {
          orderNumber,
          userId,
          addressId: dto.addressId,
          storeId: dto.storeId,
          deliveryType: dto.deliveryType,
          deliveryTime: dto.deliveryTime ? new Date(dto.deliveryTime) : null,
          comment: dto.comment,
          subtotal,
          deliveryFee,
          discount: new Prisma.Decimal(0),
          pointsUsed: pointsToUse,
          pointsDiscount,
          total,
          pointsEarned,
          items: {
            create: orderItems,
          },
        },
        include: {
          items: {
            include: {
              product: {
                select: {
                  id: true,
                  name: true,
                  nameRu: true,
                  nameKy: true,
                  images: true,
                },
              },
            },
          },
          address: true,
          store: true,
        },
      });
    });

    return this.formatOrder(order);
  }

  async findAllByUser(userId: string) {
    const orders = await this.prisma.order.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        items: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                nameRu: true,
                nameKy: true,
                images: true,
              },
            },
          },
        },
        address: true,
        store: true,
      },
    });

    return orders.map((order) => this.formatOrder(order));
  }

  async findOne(userId: string, orderId: string, isAdmin: boolean = false) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        items: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                nameRu: true,
                nameKy: true,
                images: true,
              },
            },
          },
        },
        address: true,
        store: true,
        user: {
          select: {
            id: true,
            phone: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (!isAdmin && order.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return this.formatOrder(order);
  }

  async cancel(userId: string, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    // Can only cancel pending or confirmed orders
    if (
      order.status !== OrderStatus.PENDING &&
      order.status !== OrderStatus.CONFIRMED
    ) {
      throw new BadRequestException('Cannot cancel order in current status');
    }

    // Refund points if used
    if (order.pointsUsed > 0) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { loyaltyPoints: { increment: order.pointsUsed } },
      });
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { status: OrderStatus.CANCELLED },
      include: {
        items: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                nameRu: true,
                nameKy: true,
                images: true,
              },
            },
          },
        },
        address: true,
        store: true,
      },
    });

    return this.formatOrder(updated);
  }

  async updateStatus(orderId: string, status: OrderStatus) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        items: {
          include: {
            product: {
              select: {
                id: true,
                coffeeSize: true,
              },
            },
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    const updateData: Prisma.OrderUpdateInput = { status };

    // If completing order, award loyalty points and update punch cards
    if (status === OrderStatus.DELIVERED) {
      // Award loyalty points
      if (order.pointsEarned > 0) {
        await this.prisma.user.update({
          where: { id: order.userId },
          data: { loyaltyPoints: { increment: order.pointsEarned } },
        });
      }
      updateData.completedAt = new Date();

      // Update coffee punch cards
      await this.processCoffeePunchCards(order.userId, order.items);
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: updateData,
      include: {
        items: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                nameRu: true,
                nameKy: true,
                images: true,
              },
            },
          },
        },
        address: true,
        store: true,
      },
    });

    return this.formatOrder(updated);
  }

  private async processCoffeePunchCards(
    userId: string,
    items: Array<{ quantity: number; product: { coffeeSize: CoffeeSize | null } }>,
  ) {
    // Count coffee purchases by size
    const coffeeCounts = new Map<CoffeeSize, number>();

    for (const item of items) {
      if (item.product.coffeeSize) {
        const currentCount = coffeeCounts.get(item.product.coffeeSize) || 0;
        coffeeCounts.set(item.product.coffeeSize, currentCount + item.quantity);
      }
    }

    // Add punches for each size
    for (const [size, count] of coffeeCounts) {
      await this.loyaltyService.addPunch(userId, size, count);
    }
  }

  private async generateOrderNumber(): Promise<string> {
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');

    // Get count of orders today
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const count = await this.prisma.order.count({
      where: {
        createdAt: { gte: startOfDay },
      },
    });

    const sequence = (count + 1).toString().padStart(4, '0');
    return `SHR-${dateStr}-${sequence}`;
  }

  private async getSettings() {
    const settings = await this.prisma.settings.findMany({
      where: {
        key: {
          in: [
            'loyalty_cashback_percent',
            'loyalty_max_points_use_percent',
            'delivery_fee',
            'free_delivery_min_amount',
          ],
        },
      },
    });

    const settingsMap = new Map(settings.map((s) => [s.key, s.value]));

    return {
      cashbackPercent: parseInt(settingsMap.get('loyalty_cashback_percent') || '5', 10),
      maxPointsUsePercent: parseInt(
        settingsMap.get('loyalty_max_points_use_percent') || '100',
        10,
      ),
      deliveryFee: parseInt(settingsMap.get('delivery_fee') || '100', 10),
      freeDeliveryMinAmount: parseInt(
        settingsMap.get('free_delivery_min_amount') || '1000',
        10,
      ),
    };
  }

  private formatOrder(order: any) {
    return {
      id: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      deliveryType: order.deliveryType,
      deliveryTime: order.deliveryTime,
      comment: order.comment,
      subtotal: Number(order.subtotal),
      deliveryFee: Number(order.deliveryFee),
      discount: Number(order.discount),
      pointsUsed: order.pointsUsed,
      pointsDiscount: Number(order.pointsDiscount),
      total: Number(order.total),
      pointsEarned: order.pointsEarned,
      createdAt: order.createdAt,
      completedAt: order.completedAt,
      items: order.items.map((item: any) => ({
        id: item.id,
        quantity: item.quantity,
        price: Number(item.price),
        total: Number(item.total),
        product: item.product,
      })),
      address: order.address
        ? {
            id: order.address.id,
            name: order.address.name,
            street: order.address.street,
            apartment: order.address.apartment,
          }
        : null,
      store: order.store
        ? {
            id: order.store.id,
            name: order.store.name,
            address: order.store.address,
          }
        : null,
      user: order.user,
    };
  }
}
