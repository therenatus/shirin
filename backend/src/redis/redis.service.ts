import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from 'redis';

type RedisClient = ReturnType<typeof createClient>;

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: RedisClient;

  constructor(private configService: ConfigService) {
    const host = this.configService.get<string>('redis.host') || 'localhost';
    const port = this.configService.get<number>('redis.port') || 6379;
    this.client = createClient({ socket: { host, port } });
    this.client.on('error', (err: Error) =>
      this.logger.error(`Redis error: ${err.message}`),
    );
  }

  async onModuleInit() {
    await this.client.connect();
  }

  async onModuleDestroy() {
    if (this.client.isOpen) {
      await this.client.quit();
    }
  }

  async get(key: string): Promise<string | null> {
    return this.client.get(key);
  }

  /** Returns the value and deletes the key atomically. */
  async getDel(key: string): Promise<string | null> {
    return this.client.getDel(key);
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    if (ttlSeconds) {
      await this.client.set(key, value, { EX: ttlSeconds });
    } else {
      await this.client.set(key, value);
    }
  }

  /** Sets the key only if it does not exist. Returns true if it was set. */
  async setIfAbsent(
    key: string,
    value: string,
    ttlSeconds: number,
  ): Promise<boolean> {
    const result = await this.client.set(key, value, {
      EX: ttlSeconds,
      NX: true,
    });
    return result === 'OK';
  }

  async del(...keys: string[]): Promise<number> {
    if (keys.length === 0) return 0;
    return this.client.del(keys);
  }

  /** Increments the counter and sets TTL when the key is created. */
  async incr(key: string, ttlSeconds?: number): Promise<number> {
    const value = await this.client.incr(key);
    if (value === 1 && ttlSeconds) {
      await this.client.expire(key, ttlSeconds);
    }
    return value;
  }
}
