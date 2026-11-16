import { registerAs } from '@nestjs/config';

const INSECURE_SECRETS = new Set([
  'your_jwt_secret_key',
  'your_jwt_secret_key_change_in_production',
  'your_jwt_refresh_secret_key',
  'your_jwt_refresh_secret_key_change_in_production',
]);

export default registerAs('jwt', () => {
  const secret = process.env.JWT_SECRET;
  const refreshSecret = process.env.JWT_REFRESH_SECRET;

  for (const [name, value] of [
    ['JWT_SECRET', secret],
    ['JWT_REFRESH_SECRET', refreshSecret],
  ] as const) {
    if (!value) {
      throw new Error(`${name} is not set`);
    }
    if (process.env.NODE_ENV === 'production' && INSECURE_SECRETS.has(value)) {
      throw new Error(`${name} uses a default value; set a real secret`);
    }
  }

  if (secret === refreshSecret) {
    throw new Error('JWT_SECRET and JWT_REFRESH_SECRET must differ');
  }

  return {
    secret,
    refreshSecret,
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  };
});
