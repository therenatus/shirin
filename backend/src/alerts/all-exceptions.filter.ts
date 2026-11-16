import {
  ArgumentsHost,
  Catch,
  HttpException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import type { Request } from 'express';
import { AlertsService } from './alerts.service';

/**
 * Responses stay exactly as Nest makes them. Unexpected errors (500 and
 * anything that isn't an HttpException) are logged with the request and
 * the user, and reported to the alerts chat.
 */
@Catch()
@Injectable()
export class AllExceptionsFilter extends BaseExceptionFilter {
  private readonly logger = new Logger('Errors');

  constructor(private readonly alerts: AlertsService) {
    super();
  }

  catch(exception: unknown, host: ArgumentsHost) {
    const status =
      exception instanceof HttpException ? exception.getStatus() : 500;
    if (status >= 500 && host.getType() === 'http') {
      const req = host
        .switchToHttp()
        .getRequest<Request & { user?: { id?: string } }>();
      // Path without the query string: it may contain codes or tokens
      const where = `${req.method} ${req.path}`;
      const err =
        exception instanceof Error ? exception : new Error(String(exception));
      this.logger.error(
        `${where} user=${req.user?.id ?? '-'} ${err.message}`,
        err.stack,
      );
      void this.alerts.alert(
        `5xx:${where}:${err.message.slice(0, 80)}`,
        `Ошибка 500: ${where}\n${err.message}`,
      );
    }
    super.catch(exception, host);
  }
}
