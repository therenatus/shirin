import { Injectable, Logger } from '@nestjs/common';
import { randomInt } from 'crypto';

export const STUB_SMS_CODE = '9999';

/**
 * SMS sending. Until a real provider (Nikita, Beeline) is integrated,
 * the stub mode is used: no SMS is sent and the code is always 9999.
 *
 * Stub mode is on by default outside production. In production it must be
 * enabled explicitly with SMS_STUB=true (anyone could log in as anyone).
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  readonly isStub: boolean;

  constructor() {
    const flag = process.env.SMS_STUB;
    this.isStub =
      flag !== undefined
        ? flag === 'true'
        : process.env.NODE_ENV !== 'production';

    if (this.isStub) {
      this.logger.warn(
        `SMS stub mode is ON: no SMS are sent, login code is always ${STUB_SMS_CODE}`,
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

    // TODO: Integrate SMS provider (Nikita, Beeline)
    throw new Error(
      `SMS provider is not configured; cannot send code to ${phone}. Set SMS_STUB=true to use the stub.`,
    );
  }
}
