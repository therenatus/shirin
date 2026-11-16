import { SmsService, STUB_SMS_CODE } from './sms.service';

describe('SmsService', () => {
  const env = { ...process.env };

  afterEach(() => {
    process.env = { ...env };
  });

  const create = (nodeEnv?: string, stub?: string) => {
    process.env.NODE_ENV = nodeEnv;
    if (stub === undefined) delete process.env.SMS_STUB;
    else process.env.SMS_STUB = stub;
    const service = new SmsService();
    jest.spyOn((service as any).logger, 'warn').mockImplementation(() => {});
    jest.spyOn((service as any).logger, 'log').mockImplementation(() => {});
    return service;
  };

  it('is a stub with code 9999 by default outside production', async () => {
    const service = create('development');
    expect(service.isStub).toBe(true);
    expect(service.generateCode()).toBe(STUB_SMS_CODE);
    await expect(
      service.sendCode('+996700000000', '9999'),
    ).resolves.toBeUndefined();
  });

  it('is not a stub in production unless SMS_STUB=true', () => {
    expect(create('production').isStub).toBe(false);
    expect(create('production', 'true').isStub).toBe(true);
  });

  it('can be disabled in development with SMS_STUB=false', () => {
    const service = create('development', 'false');
    expect(service.isStub).toBe(false);
    expect(service.generateCode()).toMatch(/^\d{4}$/);
  });

  it('throws when there is no provider and stub is off', async () => {
    await expect(
      create('production').sendCode('+996700000000', '1234'),
    ).rejects.toThrow('SMS provider is not configured');
  });
});
