import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { LoyaltyModule } from '../loyalty/loyalty.module';
import { StorageModule } from '../storage/storage.module';
import { OrdersScheduler } from './orders.scheduler';

@Module({
  imports: [PrismaModule, LoyaltyModule, StorageModule],
  controllers: [OrdersController],
  providers: [OrdersService, OrdersScheduler],
  exports: [OrdersService],
})
export class OrdersModule {}
