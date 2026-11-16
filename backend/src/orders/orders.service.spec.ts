import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { OrderStatus, Prisma, UserRole } from '@prisma/client';
import { OrdersService, nextStatuses } from './orders.service';
import { DeliveryType } from './dto/create-order.dto';
import { AuthUser } from '../auth/types/auth-user';

const ADMIN: AuthUser = {
  id: 'admin-1',
  phone: '+996700000000',
  role: UserRole.ADMIN,
  storeId: null,
};
const STAFF_S1: AuthUser = {
  id: 'staff-1',
  phone: '+996700000001',
  role: UserRole.STORE_STAFF,
  storeId: 's1',
};
const STAFF_S2: AuthUser = { ...STAFF_S1, id: 'staff-2', storeId: 's2' };

const D = (n: number) => new Prisma.Decimal(n);

function makeOrder(overrides: Partial<any> = {}) {
  return {
    id: 'order-1',
    orderNumber: 'SHR-20261114-0001',
    userId: 'user-1',
    status: OrderStatus.READY,
    deliveryType: DeliveryType.PICKUP,
    storeId: 's1',
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
  let events: any;
  let storage: any;
  let notifications: any;

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
              : s.in
                ? s.in.includes(order.status)
                : !s.notIn.includes(order.status));
          if (!statusOk) return { count: 0 };
          order = { ...order, ...data };
          return { count: 1 };
        }),
        create: jest.fn(async ({ data }: any) => ({
          ...makeOrder(),
          ...data,
          id: 'new-order',
          items: [],
        })),
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
      },
      user: {
        update: jest.fn(),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      address: { findFirst: jest.fn().mockResolvedValue({ id: 'a1' }) },
      store: { findFirst: jest.fn().mockResolvedValue({ id: 's1' }) },
      product: { findMany: jest.fn() },
      $transaction: jest.fn(async (arg: any) =>
        Array.isArray(arg) ? Promise.all(arg) : arg(prisma),
      ),
    };
    loyalty = {
      addPunch: jest.fn(),
      applyPoints: jest.fn().mockResolvedValue({ id: 'tx', balanceAfter: 0 }),
      getSettings: jest.fn().mockResolvedValue({
        cashbackPercent: 5,
        maxPointsUsePercent: 30,
        prepaymentTimeoutMinutes: 60,
        deliveryFee: 100,
        freeDeliveryMinAmount: 1000,
      }),
    };
    redis = { incr: jest.fn().mockResolvedValue(7) };
    events = { record: jest.fn() };
    storage = {
      isReferencePhotoOf: jest.fn((url: string, userId: string) =>
        url.includes(`/references/${userId}/`),
      ),
    };
    notifications = { notify: jest.fn() };
    service = new OrdersService(
      prisma,
      redis,
      loyalty,
      events,
      storage,
      notifications,
    );
  });

  describe('updateStatus', () => {
    it('awards points and punches exactly once on DELIVERED', async () => {
      await service.updateStatus(ADMIN, 'order-1', OrderStatus.DELIVERED);
      expect(loyalty.applyPoints).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          userId: 'user-1',
          type: 'EARN',
          points: 50,
          orderId: 'order-1',
        }),
      );
      expect(loyalty.addPunch).toHaveBeenCalledWith(prisma, 'user-1', 'M', 2);

      await expect(
        service.updateStatus(ADMIN, 'order-1', OrderStatus.DELIVERED),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(loyalty.applyPoints).toHaveBeenCalledTimes(1);
      expect(loyalty.addPunch).toHaveBeenCalledTimes(1);
    });

    it('does not award anything if the status changed concurrently', async () => {
      prisma.order.updateMany.mockResolvedValueOnce({ count: 0 });
      await expect(
        service.updateStatus(ADMIN, 'order-1', OrderStatus.DELIVERED),
      ).rejects.toMatchObject({ status: 409 });
      expect(loyalty.applyPoints).not.toHaveBeenCalled();
      expect(loyalty.addPunch).not.toHaveBeenCalled();
    });

    it('refunds used points when admin cancels', async () => {
      order = makeOrder({ status: OrderStatus.CONFIRMED, pointsUsed: 120 });
      await service.updateStatus(ADMIN, 'order-1', OrderStatus.CANCELLED);
      expect(loyalty.applyPoints).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({ type: 'REFUND', points: 120 }),
      );
    });

    it('tells the customer when a pickup order is ready', async () => {
      order = makeOrder({
        status: OrderStatus.PREPARING,
        store: { name: 'Ширин - Центр' },
      });
      await service.updateStatus(ADMIN, 'order-1', OrderStatus.READY);
      expect(notifications.notify).toHaveBeenCalledWith(
        'user-1',
        expect.objectContaining({
          title: expect.stringContaining('готов'),
          body: expect.stringContaining('Ширин - Центр'),
          data: expect.objectContaining({ orderId: 'order-1' }),
        }),
      );
    });

    it('does not notify when the status change fails', async () => {
      prisma.order.updateMany.mockResolvedValueOnce({ count: 0 });
      await expect(
        service.updateStatus(ADMIN, 'order-1', OrderStatus.DELIVERED),
      ).rejects.toBeDefined();
      expect(notifications.notify).not.toHaveBeenCalled();
    });

    it('records a status change event in the same transaction', async () => {
      await service.updateStatus(ADMIN, 'order-1', OrderStatus.DELIVERED);
      expect(events.record).toHaveBeenCalledWith(
        prisma,
        'order.status_changed',
        'order-1',
        expect.objectContaining({ from: 'READY', to: 'DELIVERED' }),
      );
    });

    it('lets store staff manage orders of their own store', async () => {
      await service.updateStatus(STAFF_S1, 'order-1', OrderStatus.DELIVERED);
      expect(order.status).toBe(OrderStatus.DELIVERED);
    });

    it("forbids store staff to touch another store's order", async () => {
      await expect(
        service.updateStatus(STAFF_S2, 'order-1', OrderStatus.DELIVERED),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.order.updateMany).not.toHaveBeenCalled();
    });

    it('rejects skipping steps', async () => {
      order = makeOrder({ status: OrderStatus.PENDING });
      await expect(
        service.updateStatus(ADMIN, 'order-1', OrderStatus.READY),
      ).rejects.toThrow('Cannot change status from PENDING to READY');
    });

    it('requires a store before confirming a delivery order', async () => {
      order = makeOrder({
        status: OrderStatus.PENDING,
        deliveryType: DeliveryType.DELIVERY,
        storeId: null,
      });
      await expect(
        service.updateStatus(ADMIN, 'order-1', OrderStatus.CONFIRMED),
      ).rejects.toThrow('Assign a store');
    });

    it('rejects transitions from CANCELLED', async () => {
      order = makeOrder({ status: OrderStatus.CANCELLED });
      await expect(
        service.updateStatus(ADMIN, 'order-1', OrderStatus.PREPARING),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('nextStatuses', () => {
    it('sends pickup orders from READY straight to DELIVERED', () => {
      expect(
        nextStatuses({ status: OrderStatus.READY, deliveryType: 'pickup' }),
      ).toEqual([OrderStatus.DELIVERED, OrderStatus.CANCELLED]);
    });

    it('sends delivery orders from READY to DELIVERING', () => {
      expect(
        nextStatuses({ status: OrderStatus.READY, deliveryType: 'delivery' }),
      ).toEqual([OrderStatus.DELIVERING, OrderStatus.CANCELLED]);
    });
  });

  describe('findAllAdmin', () => {
    it('limits store staff to their store whatever filter they send', async () => {
      await service.findAllAdmin(STAFF_S1, { storeId: 's2', unassigned: true });
      const where = prisma.order.findMany.mock.calls[0][0].where;
      expect(where.storeId).toBe('s1');
    });

    it('rejects staff without a store', async () => {
      await expect(
        service.findAllAdmin({ ...STAFF_S1, storeId: null }, {}),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('lets admins list unassigned orders', async () => {
      await service.findAllAdmin(ADMIN, { unassigned: true });
      const where = prisma.order.findMany.mock.calls[0][0].where;
      expect(where.storeId).toBeNull();
    });
  });

  describe('findOne', () => {
    it("hides another store's order from staff", async () => {
      await expect(service.findOne(STAFF_S2, 'order-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('shows the order to its owner', async () => {
      const result = await service.findOne(
        { ...STAFF_S2, id: 'user-1' },
        'order-1',
      );
      expect(result.id).toBe('order-1');
    });
  });

  describe('assignStore', () => {
    it('does not reassign a completed order', async () => {
      order = makeOrder({ status: OrderStatus.DELIVERED });
      await expect(service.assignStore(ADMIN, 'order-1', 's1')).rejects.toThrow(
        'Order is already completed',
      );
    });
  });

  describe('cancel', () => {
    it('refunds points for a pending order', async () => {
      order = makeOrder({ status: OrderStatus.PENDING, pointsUsed: 80 });
      const result = await service.cancel('user-1', 'order-1');
      expect(result.status).toBe(OrderStatus.CANCELLED);
      expect(loyalty.applyPoints).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({ type: 'REFUND', points: 80 }),
      );
    });

    it('does not refund when the order is already being prepared', async () => {
      order = makeOrder({ status: OrderStatus.PREPARING, pointsUsed: 80 });
      await expect(service.cancel('user-1', 'order-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(loyalty.applyPoints).not.toHaveBeenCalled();
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
      // cashback only on the 700 paid with money: 5% -> 35
      expect(data.pointsEarned).toBe(35);
      expect(loyalty.applyPoints).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({ type: 'REDEEM', points: -299 }),
      );
      expect(data.orderNumber).toMatch(/^SHR-\d{8}-0007$/);
    });

    it('fails when the user does not have enough points', async () => {
      loyalty.applyPoints.mockRejectedValueOnce(
        new BadRequestException('Not enough loyalty points'),
      );
      await expect(
        service.create('user-1', {
          deliveryType: DeliveryType.PICKUP,
          storeId: 's1',
          items: [{ productId: 'p1', quantity: 1 }],
          pointsToUse: 50,
        }),
      ).rejects.toThrow('Not enough loyalty points');
      // The debit runs in the same transaction as the insert, so the order
      // is rolled back; the ledger row is linked to the order
      expect(loyalty.applyPoints).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          type: 'REDEEM',
          orderId: expect.any(String),
        }),
      );
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

  describe('made-to-order items', () => {
    const cake = {
      id: 'cake',
      name: 'Торт на заказ',
      price: D(2500),
      discountPrice: null,
      isPreorder: true,
      leadTimeHours: 48,
      prepaymentPercent: 50,
      allowInscription: true,
      allowReferencePhoto: true,
    };
    const inHours = (h: number) =>
      new Date(Date.now() + h * 3600_000).toISOString();

    beforeEach(() => {
      const catalog = [
        cake,
        { id: 'p1', name: 'Эклер', price: D(200), discountPrice: null },
      ];
      prisma.product.findMany.mockImplementation(async ({ where }: any) =>
        catalog.filter((p) => where.id.in.includes(p.id)),
      );
    });

    it('requires a time no earlier than the lead time', async () => {
      const base = {
        deliveryType: DeliveryType.PICKUP,
        storeId: 's1',
        items: [{ productId: 'cake', quantity: 1 }],
      };
      await expect(service.create('user-1', base)).rejects.toThrow(
        'Choose the date and time',
      );
      await expect(
        service.create('user-1', { ...base, deliveryTime: inHours(24) }),
      ).rejects.toThrow('Earliest available time');
    });

    it('asks for 50% prepayment of the cake only and sets a deadline', async () => {
      await service.create('user-1', {
        deliveryType: DeliveryType.PICKUP,
        storeId: 's1',
        deliveryTime: inHours(49),
        items: [
          { productId: 'cake', quantity: 1, inscription: 'С днём рождения!' },
          { productId: 'p1', quantity: 2 },
        ],
      });
      const data = prisma.order.create.mock.calls[0][0].data;
      expect(Number(data.prepaymentAmount)).toBe(1250);
      expect(data.paymentStatus).toBe('PENDING');
      expect(data.paymentDueAt).toBeInstanceOf(Date);
      expect(data.items.create[0].inscription).toBe('С днём рождения!');
    });

    it('keeps customised lines of the same product separate', async () => {
      await service.create('user-1', {
        deliveryType: DeliveryType.PICKUP,
        storeId: 's1',
        deliveryTime: inHours(49),
        items: [
          { productId: 'cake', quantity: 1, inscription: 'Аня' },
          { productId: 'cake', quantity: 1, inscription: 'Боря' },
        ],
      });
      const data = prisma.order.create.mock.calls[0][0].data;
      expect(data.items.create).toHaveLength(2);
    });

    it('rejects an inscription the product does not allow', async () => {
      await expect(
        service.create('user-1', {
          deliveryType: DeliveryType.PICKUP,
          storeId: 's1',
          items: [{ productId: 'p1', quantity: 1, inscription: 'Привет' }],
        }),
      ).rejects.toThrow('inscription is not available');
    });

    it("rejects someone else's reference photo", async () => {
      await expect(
        service.create('user-1', {
          deliveryType: DeliveryType.PICKUP,
          storeId: 's1',
          deliveryTime: inHours(49),
          items: [
            {
              productId: 'cake',
              quantity: 1,
              referencePhotoUrl: 'http://s3/shirin/references/user-2/x.jpg',
            },
          ],
        }),
      ).rejects.toThrow('Reference photo not found');
    });
  });

  describe('prepayment', () => {
    it('blocks processing until the prepayment is confirmed', async () => {
      order = makeOrder({
        status: OrderStatus.PENDING,
        paymentStatus: 'PENDING',
      });
      await expect(
        service.updateStatus(ADMIN, 'order-1', OrderStatus.CONFIRMED),
      ).rejects.toThrow('Confirm the prepayment');
    });

    it('marks money for refund when a paid order is cancelled', async () => {
      order = makeOrder({
        status: OrderStatus.CONFIRMED,
        paymentStatus: 'PAID',
      });
      await service.updateStatus(ADMIN, 'order-1', OrderStatus.CANCELLED);
      expect(order.paymentStatus).toBe('REFUND_PENDING');
    });
  });
});
