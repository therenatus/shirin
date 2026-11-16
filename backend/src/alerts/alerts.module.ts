import { Global, Module } from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { AlertsService } from './alerts.service';
import { AllExceptionsFilter } from './all-exceptions.filter';

@Global()
@Module({
  providers: [
    AlertsService,
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
  ],
  exports: [AlertsService],
})
export class AlertsModule {}
