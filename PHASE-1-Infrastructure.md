# ФАЗА 1: Настройка инфраструктуры и базовой архитектуры

## 🎯 Цели фазы
- Настроить Docker окружение
- Создать структуру проекта
- Настроить базы данных и хранилище файлов
- Подготовить окружение для разработки

## ⏱ Длительность: 3-5 дней

## 📋 Предварительные требования
- Docker и Docker Compose установлены
- Git установлен
- Node.js 20+ установлен
- Flutter SDK установлен

---

## 🚀 Инструкции для Claude Code

### Шаг 1: Создание структуры проекта

```bash
# Создай структуру проекта
mkdir -p shirin-app
cd shirin-app

# Создай поддиректории
mkdir -p backend mobile admin-dashboard

# Создай корневые файлы
touch README.md .gitignore
```

**Содержимое README.md:**
```markdown
# Shirin App - Мобильное приложение кондитерской

## Структура проекта
- `backend/` - NestJS API сервер
- `mobile/` - Flutter мобильное приложение
- `admin-dashboard/` - React admin панель

## Технологии
- Backend: NestJS, PostgreSQL, Prisma, MinIO
- Mobile: Flutter, BLoC
- Admin: React, TypeScript, Tailwind CSS

## Запуск проекта
```bash
docker-compose up -d
```
```

**Содержимое .gitignore:**
```
# Environment
.env
.env.local
.env.*.local

# Dependencies
node_modules/
.pnpm-store/

# Build outputs
dist/
build/
*.js.map

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*

# Flutter
mobile/.dart_tool/
mobile/.flutter-plugins
mobile/.flutter-plugins-dependencies
mobile/.packages
mobile/build/
mobile/ios/Pods/
mobile/ios/.symlinks/
mobile/.fvm/

# Docker
.docker/

# Database
*.db
*.sqlite

# Prisma
backend/prisma/migrations/
```

---

### Шаг 2: Создание Docker Compose конфигурации

**Файл: `docker-compose.yml`**

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: shirin-postgres
    environment:
      POSTGRES_DB: shirin_db
      POSTGRES_USER: shirin_user
      POSTGRES_PASSWORD: ${DB_PASSWORD:-shirin_password_2024}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - shirin-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U shirin_user -d shirin_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  minio:
    image: minio/minio:latest
    container_name: shirin-minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minioadmin123}
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data
    networks:
      - shirin-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: shirin-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - shirin-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: shirin-backend
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://shirin_user:${DB_PASSWORD:-shirin_password_2024}@postgres:5432/shirin_db
      JWT_SECRET: ${JWT_SECRET:-your_jwt_secret_key_change_in_production}
      JWT_EXPIRES_IN: 7d
      MINIO_ENDPOINT: minio
      MINIO_PORT: 9000
      MINIO_ACCESS_KEY: ${MINIO_ROOT_USER:-minioadmin}
      MINIO_SECRET_KEY: ${MINIO_ROOT_PASSWORD:-minioadmin123}
      MINIO_USE_SSL: "false"
      REDIS_HOST: redis
      REDIS_PORT: 6379
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
      minio:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - shirin-network
    volumes:
      - ./backend:/app
      - /app/node_modules
    command: npm run start:dev

  admin-dashboard:
    build:
      context: ./admin-dashboard
      dockerfile: Dockerfile.dev
    container_name: shirin-admin
    environment:
      REACT_APP_API_URL: http://localhost:3000/api/v1
      REACT_APP_WS_URL: ws://localhost:3000
    ports:
      - "3001:3000"
    depends_on:
      - backend
    networks:
      - shirin-network
    volumes:
      - ./admin-dashboard:/app
      - /app/node_modules
    command: npm start

volumes:
  postgres_data:
    driver: local
  minio_data:
    driver: local
  redis_data:
    driver: local

networks:
  shirin-network:
    driver: bridge
```

---

### Шаг 3: Создание .env файла

**Файл: `.env`**

```env
# Database
DB_PASSWORD=shirin_secure_password_2024

# JWT
JWT_SECRET=your_very_secure_jwt_secret_key_change_this_in_production

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin_secure_2024

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# SMS Service (настроить позже)
SMS_API_KEY=
SMS_SENDER=Shirin

# Firebase (настроить позже)
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# App URLs
BACKEND_URL=http://localhost:3000
ADMIN_URL=http://localhost:3001
```

**Файл: `.env.example`**

```env
# Database
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_jwt_secret_key

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin_password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# SMS Service
SMS_API_KEY=your_sms_api_key
SMS_SENDER=Shirin

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_PRIVATE_KEY=your-private-key

# App URLs
BACKEND_URL=http://localhost:3000
ADMIN_URL=http://localhost:3001
```

---

### Шаг 4: Настройка Backend структуры

```bash
cd backend

# Инициализируй NestJS проект
npx @nestjs/cli new . --skip-git --package-manager npm

# Создай необходимые директории
mkdir -p src/common/decorators
mkdir -p src/common/filters
mkdir -p src/common/guards
mkdir -p src/common/interceptors
mkdir -p src/common/pipes
mkdir -p src/config
mkdir -p prisma
```

**Файл: `backend/Dockerfile`**

```dockerfile
FROM node:20-alpine AS development

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npx prisma generate || true

EXPOSE 3000

CMD ["npm", "run", "start:dev"]
```

**Файл: `backend/.env.example`**

```env
NODE_ENV=development
DATABASE_URL=postgresql://shirin_user:password@localhost:5432/shirin_db
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=7d
MINIO_ENDPOINT=localhost
MINIO_PORT=9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_USE_SSL=false
REDIS_HOST=localhost
REDIS_PORT=6379
```

---

### Шаг 5: Установка Backend зависимостей

**Добавь в `backend/package.json` следующие зависимости:**

```json
{
  "dependencies": {
    "@nestjs/common": "^10.3.0",
    "@nestjs/core": "^10.3.0",
    "@nestjs/platform-express": "^10.3.0",
    "@nestjs/config": "^3.1.1",
    "@nestjs/jwt": "^10.2.0",
    "@nestjs/passport": "^10.0.3",
    "@nestjs/swagger": "^7.1.17",
    "@nestjs/throttler": "^5.1.1",
    "@nestjs/websockets": "^10.3.0",
    "@nestjs/platform-socket.io": "^10.3.0",
    "@prisma/client": "^5.8.0",
    "passport": "^0.7.0",
    "passport-jwt": "^4.0.1",
    "bcrypt": "^5.1.1",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1",
    "minio": "^7.1.3",
    "redis": "^4.6.12",
    "socket.io": "^4.6.0",
    "firebase-admin": "^12.0.0"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.2.1",
    "@nestjs/schematics": "^10.0.3",
    "@nestjs/testing": "^10.3.0",
    "@types/express": "^4.17.21",
    "@types/jest": "^29.5.11",
    "@types/node": "^20.10.6",
    "@types/passport-jwt": "^4.0.0",
    "@types/bcrypt": "^5.0.2",
    "@typescript-eslint/eslint-plugin": "^6.17.0",
    "@typescript-eslint/parser": "^6.17.0",
    "eslint": "^8.56.0",
    "jest": "^29.7.0",
    "prettier": "^3.1.1",
    "prisma": "^5.8.0",
    "ts-jest": "^29.1.1",
    "ts-node": "^10.9.2",
    "typescript": "^5.3.3"
  }
}
```

**Команды для установки:**

```bash
cd backend
npm install
```

---

### Шаг 6: Настройка Prisma

**Файл: `backend/prisma/schema.prisma`**

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Пока создадим базовую модель User для проверки
model User {
  id            String    @id @default(uuid())
  phone         String    @unique
  firstName     String?
  lastName      String?
  email         String?   @unique
  avatar        String?
  loyaltyPoints Int       @default(0)
  qrCode        String    @unique @default(uuid())
  fcmToken      String?
  isActive      Boolean   @default(true)
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  @@map("users")
}

// Модель для настроек системы
model Settings {
  id          String   @id @default(uuid())
  key         String   @unique
  value       String
  description String?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  
  @@map("settings")
}
```

**Команды для инициализации Prisma:**

```bash
cd backend

# Создай миграцию
npx prisma migrate dev --name init

# Сгенерируй Prisma Client
npx prisma generate
```

---

### Шаг 7: Создание базовых конфигурационных файлов Backend

**Файл: `backend/src/config/database.config.ts`**

```typescript
import { registerAs } from '@nestjs/config';

export default registerAs('database', () => ({
  url: process.env.DATABASE_URL,
}));
```

**Файл: `backend/src/config/jwt.config.ts`**

```typescript
import { registerAs } from '@nestjs/config';

export default registerAs('jwt', () => ({
  secret: process.env.JWT_SECRET,
  expiresIn: process.env.JWT_EXPIRES_IN || '7d',
}));
```

**Файл: `backend/src/config/minio.config.ts`**

```typescript
import { registerAs } from '@nestjs/config';

export default registerAs('minio', () => ({
  endPoint: process.env.MINIO_ENDPOINT || 'localhost',
  port: parseInt(process.env.MINIO_PORT, 10) || 9000,
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
  secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin',
}));
```

**Файл: `backend/src/config/redis.config.ts`**

```typescript
import { registerAs } from '@nestjs/config';

export default registerAs('redis', () => ({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT, 10) || 6379,
}));
```

---

### Шаг 8: Настройка основного модуля Backend

**Файл: `backend/src/app.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import databaseConfig from './config/database.config';
import jwtConfig from './config/jwt.config';
import minioConfig from './config/minio.config';
import redisConfig from './config/redis.config';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig, jwtConfig, minioConfig, redisConfig],
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 1 минута
        limit: 100, // 100 запросов
      },
    ]),
  ],
})
export class AppModule {}
```

**Файл: `backend/src/main.ts`**

```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    cors: true,
  });

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

  console.log(`🚀 Application is running on: http://localhost:${port}`);
  console.log(`📚 Swagger docs: http://localhost:${port}/api/docs`);
}

bootstrap();
```

---

### Шаг 9: Создание Health Check endpoint

**Файл: `backend/src/health/health.controller.ts`**

```typescript
import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'shirin-backend',
      version: '1.0.0',
    };
  }
}
```

**Файл: `backend/src/health/health.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';

@Module({
  controllers: [HealthController],
})
export class HealthModule {}
```

**Обнови `backend/src/app.module.ts`:**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { HealthModule } from './health/health.module';
import databaseConfig from './config/database.config';
import jwtConfig from './config/jwt.config';
import minioConfig from './config/minio.config';
import redisConfig from './config/redis.config';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig, jwtConfig, minioConfig, redisConfig],
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),
    HealthModule,
  ],
})
export class AppModule {}
```

---

### Шаг 10: Настройка Admin Dashboard структуры

```bash
cd ../admin-dashboard

# Создай React приложение
npx create-react-app . --template typescript
```

**Файл: `admin-dashboard/Dockerfile.dev`**

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

**Файл: `admin-dashboard/.env.example`**

```env
REACT_APP_API_URL=http://localhost:3000/api/v1
REACT_APP_WS_URL=ws://localhost:3000
```

---

### Шаг 11: Проверка работоспособности

**Запусти все сервисы:**

```bash
# В корне проекта
docker-compose up -d

# Проверь статус контейнеров
docker-compose ps

# Проверь логи
docker-compose logs -f backend
```

**Проверь endpoints:**

```bash
# Health check
curl http://localhost:3000/api/v1/health

# Swagger docs
open http://localhost:3000/api/docs

# MinIO Console
open http://localhost:9001
# Логин: minioadmin
# Пароль: minioadmin123
```

---

## ✅ Критерии приемки Фазы 1

- [ ] Docker Compose запускается без ошибок
- [ ] PostgreSQL доступен и принимает соединения
- [ ] MinIO доступен через веб-интерфейс
- [ ] Redis работает
- [ ] Backend запускается и отвечает на `/api/v1/health`
- [ ] Swagger документация доступна
- [ ] Prisma миграции применены
- [ ] Admin Dashboard запускается (пустая страница React)
- [ ] Все сервисы могут общаться между собой

---

## 📝 Коммит изменений

```bash
# В корне проекта
git add .
git commit -m "Phase 1: Infrastructure setup - Docker, Backend skeleton, Database, MinIO, Redis"
```

---

## ➡️ Следующая фаза

После успешного завершения Фазы 1, переходи к **PHASE-2-Backend-Core.md** для создания основных модулей Backend (Prisma, Auth, Users).
