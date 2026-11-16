import { Global, Module } from '@nestjs/common';
import { IntegrationEventsService } from './integration-events.service';

@Global()
@Module({
  providers: [IntegrationEventsService],
  exports: [IntegrationEventsService],
})
export class IntegrationModule {}
