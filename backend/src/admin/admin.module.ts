import { Module } from '@nestjs/common';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';
import { PromotionsAdminController } from './promotions-admin.controller';
import { PromotionsAdminService } from './promotions-admin.service';
import { CustomersAdminController } from './customers-admin.controller';
import { CustomersAdminService } from './customers-admin.service';

/** Admin-only endpoints under /admin/*. */
@Module({
  controllers: [
    DashboardController,
    PromotionsAdminController,
    CustomersAdminController,
  ],
  providers: [DashboardService, PromotionsAdminService, CustomersAdminService],
})
export class AdminModule {}
