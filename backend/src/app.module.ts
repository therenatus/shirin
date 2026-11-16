import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';
import { SmsModule } from './sms/sms.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { StorageModule } from './storage/storage.module';
import { ProductsModule } from './products/products.module';
import { StoresModule } from './stores/stores.module';
import { AddressesModule } from './addresses/addresses.module';
import { OrdersModule } from './orders/orders.module';
import { PromotionsModule } from './promotions/promotions.module';
import { LoyaltyModule } from './loyalty/loyalty.module';
import databaseConfig from './config/database.config';
import jwtConfig from './config/jwt.config';
import storageConfig from './config/storage.config';
import redisConfig from './config/redis.config';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig, jwtConfig, storageConfig, redisConfig],
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),
    PrismaModule,
    RedisModule,
    SmsModule,
    HealthModule,
    AuthModule,
    UsersModule,
    StorageModule,
    ProductsModule,
    StoresModule,
    AddressesModule,
    OrdersModule,
    PromotionsModule,
    LoyaltyModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
