import {
  Injectable,
  Logger,
  UnauthorizedException,
  HttpException,
  HttpStatus,
  ServiceUnavailableException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { randomUUID, timingSafeEqual } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { SmsService } from '../sms/sms.service';
import { SendCodeDto } from './dto/send-code.dto';
import { VerifyCodeDto } from './dto/verify-code.dto';

const CODE_TTL_SECONDS = 300;
const RESEND_COOLDOWN_SECONDS = 60;
const MAX_VERIFY_ATTEMPTS = 5;
/** Wrong codes per phone, across resends: bounds guessing a 4-digit code. */
const MAX_FAILS_PER_HOUR = 10;
const MAX_FAILS_PER_DAY = 20;
/** SMS per phone per day, and for the whole system per day (budget). */
const MAX_SMS_PER_PHONE_PER_DAY = 5;
const DEFAULT_SMS_DAILY_LIMIT = 3000;
const HOUR = 60 * 60;
const DAY = 24 * HOUR;
const REFRESH_TTL_SECONDS = 30 * 24 * 60 * 60;

interface TokenPayload {
  sub: string;
  type: 'access' | 'refresh';
  jti?: string;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private redis: RedisService,
    private sms: SmsService,
  ) {}

  async sendCode(dto: SendCodeDto) {
    await this.ensureNotLocked(dto.phone);

    const canSend = await this.redis.setIfAbsent(
      this.cooldownKey(dto.phone),
      '1',
      RESEND_COOLDOWN_SECONDS,
    );
    if (!canSend) {
      throw new HttpException(
        'Code was sent recently, try again later',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // Counted before sending, so parallel requests cannot exceed the limits
    const phoneSent = await this.redis.incr(
      this.smsPerPhoneKey(dto.phone),
      DAY,
    );
    if (phoneSent > MAX_SMS_PER_PHONE_PER_DAY) {
      throw new HttpException(
        'Too many codes requested today, try again tomorrow',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    const totalSent = await this.redis.incr(this.smsTotalKey(), DAY);
    if (totalSent > this.smsDailyLimit()) {
      this.logger.error('Daily SMS limit reached: login codes are not sent');
      throw new ServiceUnavailableException(
        'Login is temporarily unavailable, try again later',
      );
    }

    const code = this.sms.generateCode();
    await this.redis.set(this.codeKey(dto.phone), code, CODE_TTL_SECONDS);
    // Per-code attempts start over; per-phone failure counters do not
    await this.redis.del(this.attemptsKey(dto.phone));

    try {
      await this.sms.sendCode(dto.phone, code);
    } catch (err) {
      await this.redis.del(
        this.codeKey(dto.phone),
        this.cooldownKey(dto.phone),
      );
      // Nothing was sent: do not use up the customer's daily quota
      await this.redis.decr(this.smsPerPhoneKey(dto.phone));
      await this.redis.decr(this.smsTotalKey());
      this.logger.error((err as Error).message);
      throw new ServiceUnavailableException('Failed to send SMS');
    }

    return {
      success: true,
      message: `Code sent to ${dto.phone}`,
    };
  }

  async verifyCode(dto: VerifyCodeDto) {
    const codeKey = this.codeKey(dto.phone);
    const attemptsKey = this.attemptsKey(dto.phone);

    await this.ensureNotLocked(dto.phone);

    const storedCode = await this.redis.get(codeKey);
    if (!storedCode) {
      throw new UnauthorizedException('Code expired or not requested');
    }

    // Reserve the attempt before comparing: concurrent guesses each use one
    const attempts = await this.redis.incr(attemptsKey, CODE_TTL_SECONDS);
    if (attempts > MAX_VERIFY_ATTEMPTS) {
      await this.redis.del(codeKey, attemptsKey);
      throw new HttpException(
        'Too many attempts, request a new code',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    if (!this.safeEqual(storedCode, dto.code)) {
      await this.redis.incr(this.failsHourKey(dto.phone), HOUR);
      await this.redis.incr(this.failsDayKey(dto.phone), DAY);
      if (attempts >= MAX_VERIFY_ATTEMPTS) {
        await this.redis.del(codeKey, attemptsKey);
        throw new HttpException(
          'Too many attempts, request a new code',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      throw new UnauthorizedException('Invalid code');
    }

    await this.redis.del(
      codeKey,
      attemptsKey,
      this.failsHourKey(dto.phone),
      this.failsDayKey(dto.phone),
    );

    const user = await this.prisma.user.upsert({
      where: { phone: dto.phone },
      create: { phone: dto.phone, lastLoginAt: new Date() },
      update: { lastLoginAt: new Date() },
    });

    if (!user.isActive) {
      throw new UnauthorizedException('User is blocked');
    }

    const tokens = await this.generateTokens(user.id);

    return {
      user: {
        id: user.id,
        phone: user.phone,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        loyaltyPoints: user.loyaltyPoints,
        qrCode: user.qrCode,
      },
      ...tokens,
    };
  }

  async refreshToken(refreshToken: string) {
    const payload = this.verifyRefreshToken(refreshToken);

    // Rotation: the old refresh token can only be used once
    const removed = await this.redis.del(
      this.refreshKey(payload.sub, payload.jti!),
    );
    if (removed === 0) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { isActive: true },
    });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    return this.generateTokens(payload.sub);
  }

  async logout(userId: string, refreshToken?: string) {
    if (refreshToken) {
      try {
        const payload = this.verifyRefreshToken(refreshToken);
        if (payload.sub === userId) {
          await this.redis.del(this.refreshKey(userId, payload.jti!));
        }
      } catch {
        // Token already invalid — nothing to revoke
      }
    }
    return { success: true };
  }

  private verifyRefreshToken(token: string): TokenPayload {
    let payload: TokenPayload;
    try {
      payload = this.jwtService.verify<TokenPayload>(token, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
    if (payload.type !== 'refresh' || !payload.jti) {
      throw new UnauthorizedException('Invalid refresh token');
    }
    return payload;
  }

  private async generateTokens(userId: string) {
    const jti = randomUUID();

    const accessToken = this.jwtService.sign(
      { sub: userId, type: 'access' } satisfies TokenPayload,
      {
        secret: this.configService.get<string>('jwt.secret'),
        expiresIn: this.configService.get('jwt.accessExpiresIn'),
      },
    );

    const refreshToken = this.jwtService.sign(
      { sub: userId, type: 'refresh', jti } satisfies TokenPayload,
      {
        secret: this.configService.get<string>('jwt.refreshSecret'),
        expiresIn: this.configService.get('jwt.refreshExpiresIn'),
      },
    );

    await this.redis.set(
      this.refreshKey(userId, jti),
      '1',
      REFRESH_TTL_SECONDS,
    );

    return { accessToken, refreshToken };
  }

  private safeEqual(a: string, b: string): boolean {
    const bufA = Buffer.from(a);
    const bufB = Buffer.from(b);
    return bufA.length === bufB.length && timingSafeEqual(bufA, bufB);
  }

  /** Refuses codes for a phone with too many wrong attempts recently. */
  private async ensureNotLocked(phone: string) {
    const [hour, day] = await Promise.all([
      this.redis.get(this.failsHourKey(phone)),
      this.redis.get(this.failsDayKey(phone)),
    ]);
    if (
      Number(hour ?? 0) >= MAX_FAILS_PER_HOUR ||
      Number(day ?? 0) >= MAX_FAILS_PER_DAY
    ) {
      throw new HttpException(
        'Too many wrong codes, try again later',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private smsDailyLimit() {
    const n = Number(process.env.SMS_DAILY_LIMIT);
    return Number.isFinite(n) && n > 0 ? n : DEFAULT_SMS_DAILY_LIMIT;
  }

  private failsHourKey(phone: string) {
    return `sms:fails:h:${phone}`;
  }

  private failsDayKey(phone: string) {
    return `sms:fails:d:${phone}`;
  }

  private smsPerPhoneKey(phone: string) {
    return `sms:sent:${phone}`;
  }

  private smsTotalKey() {
    return `sms:sent:total:${new Date().toISOString().slice(0, 10)}`;
  }

  private codeKey(phone: string) {
    return `sms:code:${phone}`;
  }

  private attemptsKey(phone: string) {
    return `sms:attempts:${phone}`;
  }

  private cooldownKey(phone: string) {
    return `sms:cooldown:${phone}`;
  }

  private refreshKey(userId: string, jti: string) {
    return `rt:${userId}:${jti}`;
  }
}
