import { HttpException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';

class FakeRedis {
  store = new Map<string, string>();
  async get(key: string) {
    return this.store.get(key) ?? null;
  }
  async set(key: string, value: string) {
    this.store.set(key, value);
  }
  async setIfAbsent(key: string, value: string) {
    if (this.store.has(key)) return false;
    this.store.set(key, value);
    return true;
  }
  async del(...keys: string[]) {
    let n = 0;
    for (const k of keys) if (this.store.delete(k)) n++;
    return n;
  }
  async incr(key: string) {
    const v = Number(this.store.get(key) ?? 0) + 1;
    this.store.set(key, String(v));
    return v;
  }
  async decr(key: string) {
    const v = Number(this.store.get(key) ?? 0) - 1;
    this.store.set(key, String(v));
    return v;
  }
}

const PHONE = '+996700123456';
const USER = {
  id: 'user-1',
  phone: PHONE,
  firstName: null,
  lastName: null,
  role: 'CLIENT',
  loyaltyPoints: 0,
  qrCode: 'qr-1',
  isActive: true,
};

describe('AuthService', () => {
  let service: AuthService;
  let redis: FakeRedis;
  let jwt: JwtService;
  let prisma: any;
  let sms: any;

  beforeEach(() => {
    redis = new FakeRedis();
    const config = new ConfigService({
      jwt: {
        secret: 'access-secret',
        refreshSecret: 'refresh-secret',
        accessExpiresIn: '15m',
        refreshExpiresIn: '30d',
      },
    });
    jwt = new JwtService({ secret: 'access-secret' });
    prisma = {
      user: {
        upsert: jest.fn().mockResolvedValue(USER),
        findUnique: jest.fn().mockResolvedValue({ isActive: true }),
        update: jest.fn(),
      },
    };
    sms = {
      isStub: true,
      generateCode: jest.fn(() => '9999'),
      sendCode: jest.fn().mockResolvedValue(undefined),
    };
    service = new AuthService(prisma, jwt, config, redis as any, sms);
    jest.spyOn((service as any).logger, 'error').mockImplementation(() => {});
  });

  const sendAndGetCode = async () => {
    await service.sendCode({ phone: PHONE });
    return redis.store.get(`sms:code:${PHONE}`)!;
  };

  it('stores a 4-digit code and enforces resend cooldown', async () => {
    const code = await sendAndGetCode();
    expect(code).toMatch(/^\d{4}$/);
    await expect(service.sendCode({ phone: PHONE })).rejects.toBeInstanceOf(
      HttpException,
    );
  });

  it('stub mode: code 9999 logs the user in', async () => {
    await service.sendCode({ phone: PHONE });
    expect(sms.sendCode).toHaveBeenCalledWith(PHONE, '9999');
    const result = await service.verifyCode({ phone: PHONE, code: '9999' });
    expect(result.accessToken).toBeDefined();
  });

  it('clears the code and cooldown if SMS sending fails', async () => {
    sms.sendCode.mockRejectedValueOnce(new Error('provider down'));
    await expect(service.sendCode({ phone: PHONE })).rejects.toMatchObject({
      status: 503,
    });
    expect(redis.store.has(`sms:code:${PHONE}`)).toBe(false);
    expect(redis.store.has(`sms:cooldown:${PHONE}`)).toBe(false);
    expect(redis.store.get(`sms:sent:${PHONE}`)).toBe('0');
  });

  it('limits SMS per phone per day', async () => {
    for (let i = 0; i < 5; i++) {
      await service.sendCode({ phone: PHONE });
      redis.store.delete(`sms:cooldown:${PHONE}`);
    }
    await expect(service.sendCode({ phone: PHONE })).rejects.toMatchObject({
      status: 429,
    });
  });

  it('resending does not reset the wrong-code counter', async () => {
    // 10 wrong codes across two resends lock the phone for an hour
    for (let round = 0; round < 2; round++) {
      redis.store.delete(`sms:cooldown:${PHONE}`);
      const code = await sendAndGetCode();
      const wrong = code === '1111' ? '2222' : '1111';
      for (let i = 0; i < 5; i++) {
        await service
          .verifyCode({ phone: PHONE, code: wrong })
          .catch(() => undefined);
      }
    }
    redis.store.delete(`sms:cooldown:${PHONE}`);
    await expect(service.sendCode({ phone: PHONE })).rejects.toMatchObject({
      status: 429,
    });
  });

  it('counts concurrent guesses against the per-code limit', async () => {
    const code = await sendAndGetCode();
    const wrong = code === '1111' ? '2222' : '1111';
    const results = await Promise.allSettled(
      Array.from({ length: 20 }, () =>
        service.verifyCode({ phone: PHONE, code: wrong }),
      ),
    );
    expect(results.every((r) => r.status === 'rejected')).toBe(true);
    // The code is gone: even the right one no longer works
    await expect(
      service.verifyCode({ phone: PHONE, code }),
    ).rejects.toBeDefined();
  });

  it('rejects an invalid code', async () => {
    const code = await sendAndGetCode();
    const wrong = code === '1111' ? '2222' : '1111';
    await expect(
      service.verifyCode({ phone: PHONE, code: wrong }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(prisma.user.upsert).not.toHaveBeenCalled();
  });

  it('rejects when no code was requested', async () => {
    await expect(
      service.verifyCode({ phone: PHONE, code: '1234' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('blocks the code after 5 failed attempts', async () => {
    const code = await sendAndGetCode();
    const wrong = code === '1111' ? '2222' : '1111';
    for (let i = 0; i < 4; i++) {
      await expect(
        service.verifyCode({ phone: PHONE, code: wrong }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    }
    await expect(
      service.verifyCode({ phone: PHONE, code: wrong }),
    ).rejects.toMatchObject({ status: 429 });
    // Even the correct code no longer works
    await expect(
      service.verifyCode({ phone: PHONE, code }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('logs in with the correct code once and returns the role', async () => {
    const code = await sendAndGetCode();
    const result = await service.verifyCode({ phone: PHONE, code });
    expect(result.user.role).toBe('CLIENT');
    expect(result.accessToken).toBeDefined();
    expect(result.refreshToken).toBeDefined();
    // Code is single-use
    await expect(
      service.verifyCode({ phone: PHONE, code }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  describe('tokens', () => {
    let tokens: { accessToken: string; refreshToken: string };

    beforeEach(async () => {
      const code = await sendAndGetCode();
      tokens = await service.verifyCode({ phone: PHONE, code });
    });

    it('refuses an access token on /refresh', async () => {
      await expect(
        service.refreshToken(tokens.accessToken),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rotates refresh tokens: an old one cannot be reused', async () => {
      const next = await service.refreshToken(tokens.refreshToken);
      expect(next.refreshToken).not.toBe(tokens.refreshToken);
      await expect(
        service.refreshToken(tokens.refreshToken),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      await expect(
        service.refreshToken(next.refreshToken),
      ).resolves.toBeDefined();
    });

    it('logout stops pushes to the device', async () => {
      await service.logout('user-1');
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { fcmToken: null },
      });
    });

    it('logout revokes the refresh token', async () => {
      await service.logout(USER.id, tokens.refreshToken);
      await expect(
        service.refreshToken(tokens.refreshToken),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('signs access tokens with type=access', () => {
      const payload = jwt.verify(tokens.accessToken, {
        secret: 'access-secret',
      });
      expect(payload.type).toBe('access');
    });
  });
});
