import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';

const isProduction = process.env.NODE_ENV === 'production';

/**
 * Browser origins allowed to call the API (the admin dashboard). Mobile apps
 * do not send Origin, so they are not affected. Unset in development = any.
 */
function corsOrigins(): string[] | boolean {
  const list = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  if (list.length > 0) return list;
  if (isProduction) {
    throw new Error(
      'CORS_ORIGINS must list the admin dashboard URL(s) in production',
    );
  }
  return true;
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    cors: { origin: corsOrigins(), credentials: false },
  });

  // Security headers; the API serves JSON (and Swagger only outside prod)
  app.use(helmet({ contentSecurityPolicy: isProduction ? undefined : false }));

  // Behind a reverse proxy (nginx, load balancer) the client IP comes from
  // X-Forwarded-For; without this all clients share one rate limit
  const trustProxy = Number(process.env.TRUST_PROXY ?? 0);
  if (trustProxy > 0) {
    app.getHttpAdapter().getInstance().set('trust proxy', trustProxy);
  }

  // Global prefix
  // /privacy stays at the root: app stores link to it
  app.setGlobalPrefix('api/v1', { exclude: ['privacy'] });

  // Validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger documentation: off in production unless SWAGGER=true
  const swaggerEnabled = !isProduction || process.env.SWAGGER === 'true';
  const config = new DocumentBuilder()
    .setTitle('Shirin API')
    .setDescription('API для мобильного приложения кондитерской Ширин')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('Auth', 'Аутентификация')
    .addTag('Users', 'Пользователи')
    .addTag('Products', 'Продукты')
    .addTag('Orders', 'Заказы')
    .addTag('Loyalty', 'Программа лояльности')
    .build();

  if (swaggerEnabled) {
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`Application is running on: http://localhost:${port}`);
  console.log(`Swagger docs: http://localhost:${port}/api/docs`);
}

bootstrap();
