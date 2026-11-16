import { BadRequestException, NotFoundException } from '@nestjs/common';
import { LoyaltyService } from './loyalty.service';

describe('LoyaltyService.claimFreeCoffee', () => {
  let service: LoyaltyService;
  let prisma: any;
  let card: any;

  beforeEach(() => {
    card = {
      id: 'card-1',
      userId: 'user-1',
      size: 'M',
      currentPunches: 6,
      maxPunches: 6,
      freeItemClaimed: false,
      createdAt: new Date(),
      completedAt: new Date(),
    };
    prisma = {
      user: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ id: 'user-1', isActive: true }),
      },
      coffeePunchCard: {
        findUnique: jest.fn(async () => card),
        findUniqueOrThrow: jest.fn(async () => card),
        updateMany: jest.fn(async ({ where, data }: any) => {
          if (card.currentPunches < where.currentPunches.gte)
            return { count: 0 };
          card = { ...card, ...data };
          return { count: 1 };
        }),
      },
    };
    service = new LoyaltyService(prisma);
  });

  it('gives out the coffee and resets the card', async () => {
    const result = await service.claimFreeCoffee('qr-1', 'M');
    expect(result.currentPunches).toBe(0);
    expect(result.isComplete).toBe(false);
  });

  it('cannot be claimed twice', async () => {
    await service.claimFreeCoffee('qr-1', 'M');
    await expect(service.claimFreeCoffee('qr-1', 'M')).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('rejects an unknown QR code', async () => {
    prisma.user.findUnique.mockResolvedValueOnce(null);
    await expect(service.claimFreeCoffee('nope', 'M')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
