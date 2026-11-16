import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { CreateOrderDto, DeliveryType } from './dto/create-order.dto';
import { QueryAdminOrdersDto } from './dto/query-admin-orders.dto';
import { OrderStatus, Prisma, CoffeeSize } from '@prisma/client';
import { LoyaltyService } from '../loyalty/loyalty.service';

const PRODUCT_SELECT = {
  id: true,
  name: true,
  nameRu: true,
  nameKy: true,
  images: true,
} satisfies Prisma.ProductSelect;

const ORDER_INCLUDE = {
  items: { include: { product: { select: PRODUCT_SELECT } } },
  address: true,
  store: true,
} satisfies Prisma.OrderInclude;

const ORDER_INCLUDE_WITH_USER = {
  ...ORDER_INCLUDE,
  user: {
    select: { id: true, phone: true, firstName: true, lastName: true },
  },
} satisfies Prisma.OrderInclude;

const FINAL_STATUSES: OrderStatus[] = [
  OrderStatus.DELIVERED,
  OrderStatus.CANCELLED,
];

const ORDER_SEQ_TTL_SECONDS = 2 * 24 * 60 * 60;

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private loyaltyService: LoyaltyService,
  ) {}

  async create(userId: string, dto: CreateOrderDto) {
    if (dto.deliveryType === DeliveryType.DELIVERY && !dto.addressId) {
      throw new BadRequestException('Address is required for delivery');
    }

    if (dto.deliveryType === DeliveryType.PICKUP && !dto.storeId) {
      throw new BadRequestException('Store is required for pickup');
    }

    if (dto.addressId) {
      const address = await this.prisma.address.findFirst({
        where: { id: dto.addressId, userId },
        select: { id: true },
      });
      if (!address) {
        throw new BadRequestException('Address not found');
      }
    }

    if (dto.storeId) {
      const store = await this.prisma.store.findFirst({
        where: { id: dto.storeId, isActive: true },
        select: { id: true },
      });
      if (!store) {
        throw new BadRequestException('Store not found');
      }
    }

    // Merge duplicate product lines
    const quantities = new Map<string, number>();
    for (const item of dto.items) {
      quantities.set(
        item.productId,
        (quantities.get(item.productId) || 0) + item.quantity,
      );
    }

    const productIds = [...quantities.keys()];
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds }, isAvailable: true },
    });

    if (products.length !== productIds.length) {
      throw new BadRequestException('Some products are not available');
    }

    let subtotal = new Prisma.Decimal(0);
    const orderItems = products.map((product) => {
      const quantity = quantities.get(product.id)!;
      const price = product.discountPrice || product.price;
      const total = price.mul(quantity);
      subtotal = subtotal.add(total);
      return { productId: product.id, quantity, price, total };
    });

    const settings = await this.loyaltyService.getSettings();

    let deliveryFee = new Prisma.Decimal(0);
    if (
      dto.deliveryType === DeliveryType.DELIVERY &&
      subtotal.lt(settings.freeDeliveryMinAmount)
    ) {
      deliveryFee = new Prisma.Decimal(settings.deliveryFee);
    }

    // 1 point = 1 som; points are always whole numbers
    const maxPoints = subtotal
      .mul(settings.maxPointsUsePercent)
      .div(100)
      .floor()
      .toNumber();
    const pointsToUse = Math.min(dto.pointsToUse || 0, maxPoints);
    const pointsDiscount = new Prisma.Decimal(pointsToUse);

    const total = subtotal.add(deliveryFee).sub(pointsDiscount);

    // Points to earn are based on subtotal, awarded on delivery
    const pointsEarned = subtotal
      .mul(settings.cashbackPercent)
      .div(100)
      .floor()
      .toNumber();

    const orderNumber = await this.generateOrderNumber();

    const order = await this.prisma.$transaction(async (tx) => {
      if (pointsToUse > 0) {
        // Conditional decrement prevents spending the same points twice
        const { count } = await tx.user.updateMany({
          where: { id: userId, loyaltyPoints: { gte: pointsToUse } },
          data: { loyaltyPoints: { decrement: pointsToUse } },
        });
        if (count === 0) {
          throw new BadRequestException('Not enough loyalty points');
        }
      }

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
          items: { create: orderItems },
        },
        include: ORDER_INCLUDE,
      });
    });

    return this.formatOrder(order);
  }

  async findAllByUser(userId: string) {
    const orders = await this.prisma.order.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: ORDER_INCLUDE,
    });

    return orders.map((order) => this.formatOrder(order));
  }

  async findAllAdmin(query: QueryAdminOrdersDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const where: Prisma.OrderWhereInput = query.status
      ? { status: query.status }
      : {};

    const [orders, total] = await this.prisma.$transaction([
      this.prisma.order.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: ORDER_INCLUDE_WITH_USER,
      }),
      this.prisma.order.count({ where }),
    ]);

    return {
      data: orders.map((order) => this.formatOrder(order)),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async findOne(userId: string, orderId: string, isAdmin: boolean = false) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: ORDER_INCLUDE_WITH_USER,
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

    const updated = await this.prisma.$transaction(async (tx) => {
      // Status check and change in one statement: only pending/confirmed orders
      const { count } = await tx.order.updateMany({
        where: {
          id: orderId,
          userId,
          status: { in: [OrderStatus.PENDING, OrderStatus.CONFIRMED] },
        },
        data: { status: OrderStatus.CANCELLED },
      });

      if (count === 0) {
        throw new BadRequestException('Cannot cancel order in current status');
      }

      if (order.pointsUsed > 0) {
        await tx.user.update({
          where: { id: userId },
          data: { loyaltyPoints: { increment: order.pointsUsed } },
        });
      }

      return tx.order.findUniqueOrThrow({
        where: { id: orderId },
        include: ORDER_INCLUDE,
      });
    });

    return this.formatOrder(updated);
  }

  async updateStatus(orderId: string, status: OrderStatus) {
    const updated = await this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({
        where: { id: orderId },
        include: {
          items: {
            include: { product: { select: { id: true, coffeeSize: true } } },
          },
        },
      });

      if (!order) {
        throw new NotFoundException('Order not found');
      }

      if (FINAL_STATUSES.includes(order.status)) {
        throw new BadRequestException(
          `Order is already ${order.status.toLowerCase()}`,
        );
      }

      if (order.status === status) {
        throw new BadRequestException('Order already has this status');
      }

      // Optimistic lock: fails if another request changed the status meanwhile,
      // so points/punches can never be awarded twice
      const { count } = await tx.order.updateMany({
        where: { id: orderId, status: order.status },
        data: {
          status,
          completedAt:
            status === OrderStatus.DELIVERED ? new Date() : undefined,
        },
      });

      if (count === 0) {
        throw new ConflictException('Order status was changed concurrently');
      }

      if (status === OrderStatus.DELIVERED) {
        if (order.pointsEarned > 0) {
          await tx.user.update({
            where: { id: order.userId },
            data: { loyaltyPoints: { increment: order.pointsEarned } },
          });
        }
        await this.processCoffeePunchCards(tx, order.userId, order.items);
      }

      if (status === OrderStatus.CANCELLED && order.pointsUsed > 0) {
        await tx.user.update({
          where: { id: order.userId },
          data: { loyaltyPoints: { increment: order.pointsUsed } },
        });
      }

      return tx.order.findUniqueOrThrow({
        where: { id: orderId },
        include: ORDER_INCLUDE,
      });
    });

    return this.formatOrder(updated);
  }

  private async processCoffeePunchCards(
    tx: Prisma.TransactionClient,
    userId: string,
    items: Array<{
      quantity: number;
      product: { coffeeSize: CoffeeSize | null };
    }>,
  ) {
    const coffeeCounts = new Map<CoffeeSize, number>();

    for (const item of items) {
      if (item.product.coffeeSize) {
        const currentCount = coffeeCounts.get(item.product.coffeeSize) || 0;
        coffeeCounts.set(item.product.coffeeSize, currentCount + item.quantity);
      }
    }

    for (const [size, count] of coffeeCounts) {
      await this.loyaltyService.addPunch(tx, userId, size, count);
    }
  }

  private async generateOrderNumber(): Promise<string> {
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    // Atomic per-day counter; unique even for concurrent orders
    const seq = await this.redis.incr(
      `order:seq:${dateStr}`,
      ORDER_SEQ_TTL_SECONDS,
    );
    return `SHR-${dateStr}-${seq.toString().padStart(4, '0')}`;
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
