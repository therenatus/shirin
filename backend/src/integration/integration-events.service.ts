import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';

export type IntegrationEventType =
  | 'order.created'
  | 'order.status_changed'
  | 'order.store_assigned'
  | 'loyalty.transaction';

/**
 * Outbox for external systems (1C and others).
 *
 * Always call `record` with the transaction client of the change it
 * describes, so an event exists if and only if the change was committed.
 * Consumers read `integration_events` in `id` order and keep the last id
 * they processed as their cursor.
 */
@Injectable()
export class IntegrationEventsService {
  async record(
    tx: Prisma.TransactionClient,
    type: IntegrationEventType,
    aggregateId: string,
    payload: Prisma.InputJsonObject,
  ) {
    await tx.integrationEvent.create({
      data: { type, aggregateId, payload },
    });
  }
}
