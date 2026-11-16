import { SmsService, STUB_SMS_CODE } from './sms.service';
import {
  buildNikitaXml,
  parseNikitaStatus,
  toProviderPhone,
} from './nikita.provider';

describe('SmsService', () => {
  const env = { ...process.env };

  afterEach(() => {
    process.env = { ...env };
    jest.restoreAllMocks();
  });

  const create = (vars: Record<string, string | undefined>) => {
    for (const k of [
      'NODE_ENV',
      'SMS_STUB',
      'SMS_PROVIDER',
      'SMS_NIKITA_LOGIN',
      'SMS_NIKITA_PASSWORD',
      'SMS_NIKITA_SENDER',
    ]) {
      delete process.env[k];
    }
    Object.assign(process.env, vars);
    jest
      .spyOn(require('@nestjs/common').Logger.prototype, 'warn')
      .mockImplementation(() => {});
    jest
      .spyOn(require('@nestjs/common').Logger.prototype, 'log')
      .mockImplementation(() => {});
    return new SmsService();
  };

  const nikitaVars = {
    SMS_NIKITA_LOGIN: 'shirin',
    SMS_NIKITA_PASSWORD: 'secret',
    SMS_NIKITA_SENDER: 'SHIRIN',
  };

  it('is a stub with code 9999 by default outside production', async () => {
    const service = create({ NODE_ENV: 'development' });
    expect(service.isStub).toBe(true);
    expect(service.generateCode()).toBe(STUB_SMS_CODE);
    await expect(
      service.sendCode('+996700000000', '9999'),
    ).resolves.toBeUndefined();
  });

  it('refuses to start in production with the stub', () => {
    expect(() => create({ NODE_ENV: 'production', SMS_STUB: 'true' })).toThrow(
      'cannot be used in production',
    );
    expect(() =>
      create({ NODE_ENV: 'production', SMS_PROVIDER: 'stub' }),
    ).toThrow('cannot be used in production');
  });

  it('refuses to start in production without provider credentials', () => {
    expect(() => create({ NODE_ENV: 'production' })).toThrow(
      'are required in production',
    );
  });

  it('uses the real provider in production when configured', () => {
    const service = create({ NODE_ENV: 'production', ...nikitaVars });
    expect(service.isStub).toBe(false);
    expect(service.generateCode()).toMatch(/^\d{4}$/);
  });

  it('sends the code through SMSPRO and fails on a rejected status', async () => {
    const service = create({ NODE_ENV: 'production', ...nikitaVars });
    const fetchMock = jest
      .spyOn(global, 'fetch')
      .mockResolvedValueOnce(
        new Response('<response><status>0</status></response>'),
      )
      .mockResolvedValueOnce(
        new Response('<response><status>4</status></response>'),
      );

    await service.sendCode('+996 700 123 456', '1234');
    const body = String(fetchMock.mock.calls[0][1]!.body);
    expect(body).toContain('<phone>996700123456</phone>');
    expect(body).toContain('код для входа 1234');

    await expect(service.sendCode('+996700123456', '1234')).rejects.toThrow(
      'status 4',
    );
  });

  it('throws in development when the provider is chosen but not configured', async () => {
    const service = create({ NODE_ENV: 'development', SMS_STUB: 'false' });
    await expect(service.sendCode('+996700000000', '1234')).rejects.toThrow(
      'not configured',
    );
  });
});

describe('SMSPRO request', () => {
  it('escapes XML and normalises the phone', () => {
    const xml = buildNikitaXml(
      { login: 'a&b', password: 'p<w', sender: 'SHIRIN', url: '', test: true },
      '+996 (700) 12-34-56',
      'Код <1234>',
      'id1',
    );
    expect(xml).toContain('<login>a&amp;b</login>');
    expect(xml).toContain('<pwd>p&lt;w</pwd>');
    expect(xml).toContain('<text>Код &lt;1234&gt;</text>');
    expect(xml).toContain('<test>1</test>');
    expect(toProviderPhone('+996 (700) 12-34-56')).toBe('996700123456');
  });

  it('reads the status from the response', () => {
    expect(
      parseNikitaStatus('<response><id>1</id><status>0</status></response>'),
    ).toBe(0);
    expect(parseNikitaStatus('garbage')).toBeNull();
  });
});
