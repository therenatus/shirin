import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

const withTimeout = <T>(p: Promise<T>, ms: number) =>
  Promise.race([
    p,
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error('timeout')), ms),
    ),
  ]);

/**
 * Point uptime monitoring at GET /api/v1/health: 200 when the database and
 * Redis answer, 503 otherwise.
 */
@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  @Get()
  @SkipThrottle()
  @ApiOperation({ summary: 'Health check: database and Redis' })
  async check() {
    const [db, redis] = await Promise.allSettled([
      withTimeout(this.prisma.$queryRaw`SELECT 1`, 2000),
      withTimeout(this.redis.ping(), 2000),
    ]);
    const checks = {
      database: db.status === 'fulfilled' ? 'ok' : 'down',
      redis: redis.status === 'fulfilled' ? 'ok' : 'down',
    };
    const body = {
      status: checks.database === 'ok' && checks.redis === 'ok' ? 'ok' : 'down',
      checks,
      timestamp: new Date().toISOString(),
      service: 'shirin-backend',
    };
    if (body.status !== 'ok') throw new ServiceUnavailableException(body);
    return body;
  }
}
