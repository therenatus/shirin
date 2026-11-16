import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { UsersService } from './users.service';

describe('UsersService.deleteAccount', () => {
  let prisma: any;
  let loyalty: any;
  let service: UsersService;
  let user: any;

  beforeEach(() => {
    user = { id: 'u1', role: 'CLIENT', loyaltyPoints: 120, isActive: true };
    const del = () => ({ deleteMany: jest.fn() });
    prisma = {
      user: {
        findUnique: jest.fn(async () => user),
        update: jest.fn(async ({ data }: any) => Object.assign(user, data)),
      },
      order: { count: jest.fn().mockResolvedValue(0) },
      address: del(),
      favorite: del(),
      notification: del(),
      chatMessage: del(),
      coffeePunchCard: del(),
      raffleEntry: del(),
      $transaction: jest.fn(async (cb: any) => cb(prisma)),
    };
    loyalty = { applyPoints: jest.fn() };
    service = new UsersService(prisma, loyalty);
  });

  it('erases personal data, frees the phone and deactivates', async () => {
    await service.deleteAccount('u1');
    const data = prisma.user.update.mock.calls[0][0].data;
    expect(data).toMatchObject({
      phone: 'deleted:u1',
      firstName: null,
      lastName: null,
      email: null,
      birthDate: null,
      fcmToken: null,
      isActive: false,
    });
    expect(prisma.address.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'u1' },
    });
  });

  it('writes off points through the ledger', async () => {
    await service.deleteAccount('u1');
    expect(loyalty.applyPoints).toHaveBeenCalledWith(
      prisma,
      expect.objectContaining({ userId: 'u1', points: -120, type: 'ADJUST' }),
    );
  });

  it('refuses while there are active orders', async () => {
    prisma.order.count.mockResolvedValueOnce(1);
    await expect(service.deleteAccount('u1')).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(prisma.user.update).not.toHaveBeenCalled();
  });

  it('does not let employees delete themselves', async () => {
    user.role = 'ADMIN';
    await expect(service.deleteAccount('u1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
