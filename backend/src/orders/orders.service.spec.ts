import { BadRequestException } from '@nestjs/common';
import { OrderStatus, Prisma } from '@prisma/client';
import { OrdersService } from './orders.service';
import { DeliveryType } from './dto/create-order.dto';

const D = (n: number) => new Prisma.Decimal(n);

function makeOrder(overrides: Partial<any> = {}) {
  return {
    id: 'order-1',
    orderNumber: 'SHR-20261114-0001',
    userId: 'user-1',
    status: OrderStatus.READY,
    subtotal: D(1000),
    deliveryFee: D(0),
    discount: D(0),
    pointsUsed: 0,
    pointsDiscount: D(0),
    total: D(1000),
    pointsEarned: 50,
    items: [
      {
        id: 'i1',
        quantity: 2,
        price: D(500),
        total: D(1000),
        product: { id: 'p1', coffeeSize: 'M' },
      },
    ],
    address: null,
    store: null,
    ...overrides,
  };
}

describe('OrdersService', () => {
  let service: OrdersService;
  let prisma: any;
  let loyalty: any;
  let redis: any;
  let order: any;

  beforeEach(() => {
    order = makeOrder();
    prisma = {
      order: {
        findUnique: jest.fn(async () => order),
        findUniqueOrThrow: jest.fn(async () => order),
        updateMany: jest.fn(async ({ where, data }: any) => {
          const s = where.status;
          const statusOk =
            s === undefined ||
            (typeof s === 'string'
              ? s === order.status
              : s.in.includes(order.status));
          if (!statusOk) return { count: 0 };
          order = { ...order, ...data };
          return { count: 1 };
        }),
        create: jest.fn(async ({ data }: any) => ({
          ...makeOrder(),
          ...data,
          items: [],
        })),
      },
      user: {
        update: jest.fn(),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      address: { findFirst: jest.fn().mockResolvedValue({ id: 'a1' }) },
      store: { findFirst: jest.fn().mockResolvedValue({ id: 's1' }) },
      product: { findMany: jest.fn() },
      $transaction: jest.fn(async (cb: any) => cb(prisma)),
    };
    loyalty = {
      addPunch: jest.fn(),
      getSettings: jest.fn().mockResolvedValue({
        cashbackPercent: 5,
        maxPointsUsePercent: 30,
        deliveryFee: 100,
        freeDeliveryMinAmount: 1000,
      }),
    };
    redis = { incr: jest.fn().mockResolvedValue(7) };
    service = new OrdersService(prisma, redis, loyalty);
  });

  describe('updateStatus', () => {
    it('awards points and punches exactly once on DELIVERED', async () => {
      await service.updateStatus('order-1', OrderStatus.DELIVERED);
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { loyaltyPoints: { increment: 50 } },
      });
      expect(loyalty.addPunch).toHaveBeenCalledWith(prisma, 'user-1', 'M', 2);

      await expect(
        service.updateStatus('order-1', OrderStatus.DELIVERED),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.user.update).toHaveBeenCalledTimes(1);
      expect(loyalty.addPunch).toHaveBeenCalledTimes(1);
    });

    it('does not award anything if the status changed concurrently', async () => {
      prisma.order.updateMany.mockResolvedValueOnce({ count: 0 });
      await expect(
        service.updateStatus('order-1', OrderStatus.DELIVERED),
      ).rejects.toMatchObject({ status: 409 });
      expect(prisma.user.update).not.toHaveBeenCalled();
      expect(loyalty.addPunch).not.toHaveBeenCalled();
    });

    it('refunds used points when admin cancels', async () => {
      order = makeOrder({ status: OrderStatus.CONFIRMED, pointsUsed: 120 });
      await service.updateStatus('order-1', OrderStatus.CANCELLED);
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { loyaltyPoints: { increment: 120 } },
      });
    });

    it('rejects transitions from CANCELLED', async () => {
      order = makeOrder({ status: OrderStatus.CANCELLED });
      await expect(
        service.updateStatus('order-1', OrderStatus.PREPARING),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('cancel', () => {
    it('refunds points for a pending order', async () => {
      order = makeOrder({ status: OrderStatus.PENDING, pointsUsed: 80 });
      const result = await service.cancel('user-1', 'order-1');
      expect(result.status).toBe(OrderStatus.CANCELLED);
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { loyaltyPoints: { increment: 80 } },
      });
    });

    it('does not refund when the order is already being prepared', async () => {
      order = makeOrder({ status: OrderStatus.PREPARING, pointsUsed: 80 });
      await expect(service.cancel('user-1', 'order-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prisma.user.update).not.toHaveBeenCalled();
    });
  });

  describe('create', () => {
    beforeEach(() => {
      prisma.product.findMany.mockResolvedValue([
        { id: 'p1', price: D(333), discountPrice: null },
      ]);
    });

    it('caps points to a whole number and merges duplicate items', async () => {
      await service.create('user-1', {
        deliveryType: DeliveryType.PICKUP,
        storeId: 's1',
        items: [
          { productId: 'p1', quantity: 1 },
          { productId: 'p1', quantity: 2 },
        ],
        pointsToUse: 10000,
      });

      // subtotal 999, 30% cap = 299.7 -> 299 points
      const data = prisma.order.create.mock.calls[0][0].data;
      expect(data.items.create).toHaveLength(1);
      expect(data.items.create[0].quantity).toBe(3);
      expect(data.pointsUsed).toBe(299);
      expect(Number(data.total)).toBe(700);
      expect(data.pointsEarned).toBe(49);
      expect(data.orderNumber).toMatch(/^SHR-\d{8}-0007$/);
    });

    it('fails when the user does not have enough points', async () => {
      prisma.user.updateMany.mockResolvedValueOnce({ count: 0 });
      await expect(
        service.create('user-1', {
          deliveryType: DeliveryType.PICKUP,
          storeId: 's1',
          items: [{ productId: 'p1', quantity: 1 }],
          pointsToUse: 50,
        }),
      ).rejects.toThrow('Not enough loyalty points');
      expect(prisma.order.create).not.toHaveBeenCalled();
    });

    it("rejects someone else's address", async () => {
      prisma.address.findFirst.mockResolvedValueOnce(null);
      await expect(
        service.create('user-1', {
          deliveryType: DeliveryType.DELIVERY,
          addressId: 'foreign',
          items: [{ productId: 'p1', quantity: 1 }],
        }),
      ).rejects.toThrow('Address not found');
    });
  });
});
