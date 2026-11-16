import { HttpException, ServiceUnavailableException } from '@nestjs/common';
import { AlertsService } from './alerts.service';
import { AllExceptionsFilter } from './all-exceptions.filter';
import { HealthController } from '../health/health.controller';

describe('AlertsService', () => {
  const env = { ...process.env };
  afterEach(() => {
    process.env = { ...env };
    jest.restoreAllMocks();
  });

  const make = () => {
    process.env.ALERT_TELEGRAM_BOT_TOKEN = 't';
    process.env.ALERT_TELEGRAM_CHAT_ID = 'c';
    jest
      .spyOn(require('@nestjs/common').Logger.prototype, 'warn')
      .mockImplementation(() => {});
    const fetchMock = jest
      .spyOn(global, 'fetch')
      .mockResolvedValue(new Response('{}'));
    return { service: new AlertsService(), fetchMock };
  };

  it('sends once per key and counts muted repeats', async () => {
    const { service, fetchMock } = make();
    await service.alert('k', 'first');
    await service.alert('k', 'second');
    await service.alert('other', 'x');
    expect(fetchMock).toHaveBeenCalledTimes(2);

    // 11 minutes later the next one goes out with the muted count
    jest.spyOn(Date, 'now').mockReturnValue(Date.now() + 11 * 60_000);
    await service.alert('k', 'third');
    const body = JSON.parse(String(fetchMock.mock.calls[2][1]!.body));
    expect(body.text).toContain('third');
    expect(body.text).toContain('ещё 1');
  });

  it('never throws when Telegram is down', async () => {
    const { service, fetchMock } = make();
    jest
      .spyOn(require('@nestjs/common').Logger.prototype, 'error')
      .mockImplementation(() => {});
    fetchMock.mockRejectedValueOnce(new Error('network'));
    await expect(service.alert('k', 'x')).resolves.toBeUndefined();
  });
});

describe('AllExceptionsFilter', () => {
  const host = (path = '/api/v1/orders') =>
    ({
      getType: () => 'http',
      switchToHttp: () => ({
        getRequest: () => ({ method: 'POST', path, user: { id: 'u1' } }),
      }),
    }) as any;

  it('alerts on unexpected errors but not on client errors', () => {
    const alerts = { alert: jest.fn() } as any;
    const filter = new AllExceptionsFilter(alerts);
    jest
      .spyOn(require('@nestjs/core').BaseExceptionFilter.prototype, 'catch')
      .mockImplementation(() => {});
    jest
      .spyOn(require('@nestjs/common').Logger.prototype, 'error')
      .mockImplementation(() => {});

    filter.catch(new HttpException('Bad', 400), host());
    expect(alerts.alert).not.toHaveBeenCalled();

    filter.catch(new Error('db exploded'), host());
    expect(alerts.alert).toHaveBeenCalledWith(
      expect.stringContaining('POST /api/v1/orders'),
      expect.stringContaining('db exploded'),
    );
  });
});

describe('HealthController', () => {
  it('is ok when database and Redis answer', async () => {
    const c = new HealthController(
      { $queryRaw: jest.fn().mockResolvedValue([1]) } as any,
      { ping: jest.fn().mockResolvedValue('PONG') } as any,
    );
    await expect(c.check()).resolves.toMatchObject({ status: 'ok' });
  });

  it('returns 503 naming what is down', async () => {
    const c = new HealthController(
      { $queryRaw: jest.fn().mockRejectedValue(new Error('x')) } as any,
      { ping: jest.fn().mockResolvedValue('PONG') } as any,
    );
    await expect(c.check()).rejects.toBeInstanceOf(ServiceUnavailableException);
    await c
      .check()
      .catch((e) =>
        expect(e.getResponse().checks).toEqual({
          database: 'down',
          redis: 'ok',
        }),
      );
  });
});
