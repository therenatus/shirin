import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { OrdersService } from './orders.service';

@Injectable()
export class OrdersScheduler {
  private readonly logger = new Logger(OrdersScheduler.name);
  private running = false;

  constructor(private ordersService: OrdersService) {}

  /** Cancels made-to-order orders whose prepayment did not arrive in time. */
  @Cron(CronExpression.EVERY_MINUTE)
  async cancelExpiredUnpaid() {
    if (this.running) return; // previous run still in progress
    this.running = true;
    try {
      const count = await this.ordersService.cancelExpiredUnpaid();
      if (count > 0) {
        this.logger.log(`Cancelled ${count} unpaid order(s)`);
      }
    } catch (e) {
      this.logger.error(`Unpaid order cleanup failed: ${(e as Error).message}`);
    } finally {
      this.running = false;
    }
  }
}
