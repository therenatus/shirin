import { Injectable, Logger } from '@nestjs/common';
import { randomInt } from 'crypto';
import {
  NIKITA_DEFAULT_URL,
  NikitaConfig,
  sendViaNikita,
} from './nikita.provider';

export const STUB_SMS_CODE = '9999';

/**
 * Sends login codes.
 *
 * SMS_PROVIDER selects the gateway: `stub` (nothing is sent, the code is
 * always 9999) or `nikita` (SMSPRO, see nikita.provider.ts).
 * Default: `stub` outside production. In production the stub is refused and
 * the provider settings are required, so the server will not start in a
 * state where anyone can log in as anyone.
 *
 * SMS_STUB=true is still accepted as a shortcut for SMS_PROVIDER=stub.
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  readonly isStub: boolean;
  private readonly nikita?: NikitaConfig;

  constructor() {
    const isProduction = process.env.NODE_ENV === 'production';
    const provider =
      process.env.SMS_PROVIDER ??
      (process.env.SMS_STUB === 'true'
        ? 'stub'
        : process.env.SMS_STUB === 'false' || isProduction
          ? 'nikita'
          : 'stub');

    if (provider === 'stub') {
      if (isProduction) {
        throw new Error(
          'SMS stub cannot be used in production: set SMS_PROVIDER=nikita and its credentials',
        );
      }
      this.isStub = true;
      this.logger.warn(
        `SMS stub mode is ON: no SMS are sent, login code is always ${STUB_SMS_CODE}`,
      );
      return;
    }

    if (provider !== 'nikita') {
      throw new Error(
        `Unknown SMS_PROVIDER "${provider}" (use stub or nikita)`,
      );
    }

    this.isStub = false;
    const login = process.env.SMS_NIKITA_LOGIN;
    const password = process.env.SMS_NIKITA_PASSWORD;
    const sender = process.env.SMS_NIKITA_SENDER;
    if (login && password && sender) {
      this.nikita = {
        login,
        password,
        sender,
        url: process.env.SMS_NIKITA_URL || NIKITA_DEFAULT_URL,
        test: process.env.SMS_NIKITA_TEST === 'true',
      };
    } else if (isProduction) {
      throw new Error(
        'SMS_NIKITA_LOGIN, SMS_NIKITA_PASSWORD and SMS_NIKITA_SENDER are required in production',
      );
    }
  }

  generateCode(): string {
    return this.isStub ? STUB_SMS_CODE : randomInt(1000, 10000).toString();
  }

  async sendCode(phone: string, code: string): Promise<void> {
    if (this.isStub) {
      this.logger.log(`[stub] SMS code for ${phone}: ${code}`);
      return;
    }
    if (!this.nikita) {
      throw new Error(
        'SMS provider is not configured: set SMS_NIKITA_LOGIN, SMS_NIKITA_PASSWORD, SMS_NIKITA_SENDER',
      );
    }
    await sendViaNikita(
      this.nikita,
      phone,
      `Ширин: код для входа ${code}. Никому его не сообщайте.`,
    );
  }
}
