import { NotificationsService } from './notifications.service';
import { orderStatusMessage } from './messages';

describe('NotificationsService', () => {
  let prisma: any;
  let service: NotificationsService;
  let send: jest.Mock;

  beforeEach(() => {
    delete process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
    prisma = {
      notification: { create: jest.fn() },
      user: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ fcmToken: 'tok', isActive: true }),
        updateMany: jest.fn(),
      },
    };
    jest
      .spyOn(require('@nestjs/common').Logger.prototype, 'warn')
      .mockImplementation(() => {});
    jest
      .spyOn(require('@nestjs/common').Logger.prototype, 'error')
      .mockImplementation(() => {});
    service = new NotificationsService(prisma);
    send = jest.fn();
    (service as any).messaging = { send };
  });

  afterEach(() => jest.restoreAllMocks());

  const input = {
    title: 'T',
    body: 'B',
    type: 'order_status' as const,
    data: { orderId: 'o1' },
  };

  it('stores the notification and sends a push', async () => {
    await service.notify('u1', input);
    expect(prisma.notification.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId: 'u1',
        title: 'T',
        data: '{"orderId":"o1"}',
      }),
    });
    expect(send).toHaveBeenCalledWith(
      expect.objectContaining({
        token: 'tok',
        data: { type: 'order_status', orderId: 'o1' },
      }),
    );
  });

  it('only stores when push is not configured', async () => {
    const plain = new NotificationsService(prisma);
    expect(plain.pushEnabled).toBe(false);
    await plain.notify('u1', input);
    expect(prisma.notification.create).toHaveBeenCalled();
  });

  it('drops a dead device token', async () => {
    send.mockRejectedValueOnce({
      code: 'messaging/registration-token-not-registered',
    });
    await service.notify('u1', input);
    expect(prisma.user.updateMany).toHaveBeenCalledWith({
      where: { id: 'u1', fcmToken: 'tok' },
      data: { fcmToken: null },
    });
  });

  it('never throws, even if storing fails', async () => {
    prisma.notification.create.mockRejectedValueOnce(new Error('db down'));
    await expect(service.notify('u1', input)).resolves.toBeUndefined();
  });

  it('skips noisy statuses and tells about cashback on completion', () => {
    const o = {
      id: 'o1',
      orderNumber: 'SHR-1',
      deliveryType: 'delivery',
      pointsEarned: 35,
    };
    expect(orderStatusMessage(o, 'PREPARING')).toBeNull();
    expect(orderStatusMessage(o, 'READY')).toBeNull();
    expect(orderStatusMessage(o, 'DELIVERED')?.body).toContain('35 баллов');
  });
});
