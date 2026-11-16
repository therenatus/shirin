import { BadRequestException, NotFoundException } from '@nestjs/common';
import { startOfBusinessDay } from './dashboard.service';
import { CustomersAdminService } from './customers-admin.service';
import { PromotionsAdminService } from './promotions-admin.service';

describe('startOfBusinessDay (Bishkek, UTC+6)', () => {
  it('00:30 in Bishkek belongs to the new day', () => {
    // 2026-11-16 18:30 UTC = 2026-11-17 00:30 Bishkek
    expect(
      startOfBusinessDay(new Date('2026-11-16T18:30:00Z')).toISOString(),
    ).toBe('2026-11-16T18:00:00.000Z');
  });

  it('23:00 in Bishkek still belongs to the same day', () => {
    // 2026-11-17 17:00 UTC = 2026-11-17 23:00 Bishkek
    expect(
      startOfBusinessDay(new Date('2026-11-17T17:00:00Z')).toISOString(),
    ).toBe('2026-11-16T18:00:00.000Z');
  });
});

describe('CustomersAdminService.setBlocked', () => {
  const make = (user: any) => {
    const prisma: any = {
      user: {
        findUnique: jest.fn().mockResolvedValue(user),
        update: jest.fn(async ({ data }: any) => ({ id: 'u1', ...data })),
      },
    };
    return { prisma, service: new CustomersAdminService(prisma) };
  };

  it('blocks a customer and stops pushes to them', async () => {
    const { prisma, service } = make({
      role: 'CLIENT',
      phone: '+996700111111',
    });
    await service.setBlocked('u1', true);
    expect(prisma.user.update.mock.calls[0][0].data).toEqual({
      isActive: false,
      fcmToken: null,
    });
  });

  it('does not touch employees or deleted accounts', async () => {
    await expect(
      make({ role: 'ADMIN', phone: '+996700000000' }).service.setBlocked(
        'u1',
        true,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      make({ role: 'CLIENT', phone: 'deleted:u1' }).service.setBlocked(
        'u1',
        true,
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});

describe('PromotionsAdminService', () => {
  it('rejects an end date before the start date', async () => {
    const service = new PromotionsAdminService({
      promotion: { create: jest.fn() },
    } as any);
    await expect(
      service.create({
        titleRu: 'Скидка',
        descriptionRu: 'Текст',
        image: 'https://x/y.png',
        type: 'DISCOUNT',
        startDate: '2026-12-10',
        endDate: '2026-12-01',
      }),
    ).rejects.toThrow('End date must be after start date');
  });
});
