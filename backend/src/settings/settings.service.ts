import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type Rule =
  | { kind: 'int'; min: number; max: number }
  | { kind: 'text'; max: number }
  | { kind: 'url' };

/**
 * Settings an admin may change from the dashboard, with validation.
 * Anything not listed (e.g. catalog_master) is changed only deliberately.
 */
const EDITABLE: Record<string, Rule> = {
  loyalty_cashback_percent: { kind: 'int', min: 0, max: 50 },
  loyalty_max_points_use_percent: { kind: 'int', min: 0, max: 100 },
  loyalty_max_receipt_amount: { kind: 'int', min: 100, max: 10_000_000 },
  loyalty_daily_earn_limit: { kind: 'int', min: 0, max: 1_000_000 },
  delivery_fee: { kind: 'int', min: 0, max: 100_000 },
  free_delivery_min_amount: { kind: 'int', min: 0, max: 10_000_000 },
  prepayment_timeout_minutes: { kind: 'int', min: 5, max: 7 * 24 * 60 },
  payment_details: { kind: 'text', max: 1000 },
  payment_qr_url: { kind: 'url' },
};

@Injectable()
export class SettingsService {
  constructor(private prisma: PrismaService) {}

  async listEditable() {
    const rows = await this.prisma.settings.findMany({
      where: { key: { in: Object.keys(EDITABLE) } },
      orderBy: { key: 'asc' },
    });
    const byKey = new Map(rows.map((r) => [r.key, r]));
    return Object.keys(EDITABLE).map((key) => ({
      key,
      value: byKey.get(key)?.value ?? null,
      description: byKey.get(key)?.description ?? null,
    }));
  }

  async update(key: string, raw: string) {
    const rule = EDITABLE[key];
    if (!rule) {
      throw new NotFoundException('Setting cannot be changed here');
    }
    const value = this.validate(rule, raw.trim());
    await this.prisma.settings.upsert({
      where: { key },
      create: { key, value },
      update: { value },
    });
    return { key, value };
  }

  private validate(rule: Rule, value: string): string {
    switch (rule.kind) {
      case 'int': {
        if (!/^\d+$/.test(value))
          throw new BadRequestException('Enter a whole number');
        const n = Number(value);
        if (n < rule.min || n > rule.max) {
          throw new BadRequestException(
            `Value must be between ${rule.min} and ${rule.max}`,
          );
        }
        return String(n);
      }
      case 'text':
        if (value.length > rule.max)
          throw new BadRequestException(`At most ${rule.max} characters`);
        return value;
      case 'url':
        if (value && !/^https?:\/\/\S+$/.test(value)) {
          throw new BadRequestException(
            'Enter a link starting with http:// or https://',
          );
        }
        return value;
    }
  }
}
