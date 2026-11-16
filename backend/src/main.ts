import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    cors: true,
  });

  // Behind a reverse proxy (nginx, load balancer) the client IP comes from
  // X-Forwarded-For; without this all clients share one rate limit
  const trustProxy = Number(process.env.TRUST_PROXY ?? 0);
  if (trustProxy > 0) {
    app.getHttpAdapter().getInstance().set('trust proxy', trustProxy);
  }

  // Global prefix
  app.setGlobalPrefix('api/v1');

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

  // Swagger documentation
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

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`Application is running on: http://localhost:${port}`);
  console.log(`Swagger docs: http://localhost:${port}/api/docs`);
}

bootstrap();
