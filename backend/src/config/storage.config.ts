import { registerAs } from '@nestjs/config';

/**
 * S3-compatible object storage (SeaweedFS locally, any S3 provider in production).
 * The `minio` npm package is used only as a generic S3 client.
 */
export default registerAs('storage', () => {
  const endPoint = process.env.S3_ENDPOINT || 'localhost';
  const port = parseInt(process.env.S3_PORT ?? '8333', 10);
  const useSSL = process.env.S3_USE_SSL === 'true';

  const accessKey = process.env.S3_ACCESS_KEY;
  const secretKey = process.env.S3_SECRET_KEY;
  if (!accessKey || !secretKey) {
    throw new Error('S3_ACCESS_KEY and S3_SECRET_KEY must be set');
  }

  return {
    endPoint,
    port,
    useSSL,
    accessKey,
    secretKey,
    bucket: process.env.S3_BUCKET || 'shirin',
    // Base URL clients (mobile app, admin) use to download public files.
    // Differs from the internal endpoint when running in Docker.
    publicUrl: (
      process.env.S3_PUBLIC_URL ||
      `${useSSL ? 'https' : 'http'}://${endPoint}:${port}`
    ).replace(/\/+$/, ''),
  };
});
