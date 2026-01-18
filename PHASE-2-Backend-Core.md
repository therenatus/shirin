# ФАЗА 2: Backend Core - Prisma, Auth, Users

## 🎯 Цели фазы
- Создать полную Prisma схему с всеми моделями
- Реализовать Prisma модуль для работы с БД
- Реализовать Auth модуль (SMS аутентификация)
- Реализовать Users модуль
- Настроить JWT Guards и защиту endpoints

## ⏱ Длительность: 7-10 дней

## 📋 Предварительные требования
- Фаза 1 завершена успешно
- Backend запускается
- База данных доступна

---

## 🚀 Инструкции для Claude Code

### Шаг 1: Обновление Prisma Schema с полными моделями

**Файл: `backend/prisma/schema.prisma`**

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum UserRole {
  CLIENT
  ADMIN
  SUPPORT
}

enum OrderStatus {
  PENDING
  CONFIRMED
  PREPARING
  READY
  DELIVERING
  DELIVERED
  CANCELLED
}

enum PromotionType {
  DISCOUNT
  CASHBACK
  GIFT
  COMBO
}

model User {
  id            String    @id @default(uuid())
  phone         String    @unique
  password      String?
  firstName     String?
  lastName      String?
  email         String?   @unique
  avatar        String?
  birthDate     DateTime?
  role          UserRole  @default(CLIENT)
  isActive      Boolean   @default(true)
  fcmToken      String?
  
  // Loyalty program
  loyaltyPoints Int       @default(0)
  qrCode        String    @unique @default(uuid())
  
  // Metadata
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  lastLoginAt   DateTime?
  
  // Relations
  orders        Order[]
  addresses     Address[]
  favorites     Favorite[]
  reviews       Review[]
  notifications Notification[]
  chatMessages  ChatMessage[]
  raffleEntries RaffleEntry[]
  
  @@map("users")
}

model Category {
  id          String    @id @default(uuid())
  name        String
  nameKy      String?
  nameRu      String?
  description String?
  image       String?
  icon        String?
  sortOrder   Int       @default(0)
  isActive    Boolean   @default(true)
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  
  products    Product[]
  
  @@map("categories")
}

model Product {
  id             String    @id @default(uuid())
  name           String
  nameKy         String?
  nameRu         String?
  description    String?
  descriptionKy  String?
  descriptionRu  String?
  price          Decimal   @db.Decimal(10, 2)
  discountPrice  Decimal?  @db.Decimal(10, 2)
  images         String[]
  ingredients    String?
  weight         Int?
  calories       Int?
  isAvailable    Boolean   @default(true)
  isNew          Boolean   @default(false)
  isBestseller   Boolean   @default(false)
  sortOrder      Int       @default(0)
  createdAt      DateTime  @default(now())
  updatedAt      DateTime  @updatedAt
  
  categoryId     String
  category       Category  @relation(fields: [categoryId], references: [id])
  
  orderItems     OrderItem[]
  favorites      Favorite[]
  reviews        Review[]
  
  @@map("products")
}

model Store {
  id          String    @id @default(uuid())
  name        String
  nameKy      String?
  nameRu      String?
  address     String
  addressKy   String?
  addressRu   String?
  latitude    Decimal   @db.Decimal(10, 8)
  longitude   Decimal   @db.Decimal(11, 8)
  phone       String
  workHours   String
  isActive    Boolean   @default(true)
  image       String?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  
  orders      Order[]
  
  @@map("stores")
}

model Address {
  id          String    @id @default(uuid())
  name        String
  street      String
  apartment   String?
  entrance    String?
  floor       String?
  intercom    String?
  latitude    Decimal?  @db.Decimal(10, 8)
  longitude   Decimal?  @db.Decimal(11, 8)
  isDefault   Boolean   @default(false)
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  
  userId      String
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  orders      Order[]
  
  @@map("addresses")
}

model Order {
  id              String      @id @default(uuid())
  orderNumber     String      @unique
  status          OrderStatus @default(PENDING)
  
  subtotal        Decimal     @db.Decimal(10, 2)
  deliveryFee     Decimal     @db.Decimal(10, 2) @default(0)
  discount        Decimal     @db.Decimal(10, 2) @default(0)
  pointsUsed      Int         @default(0)
  pointsDiscount  Decimal     @db.Decimal(10, 2) @default(0)
  total           Decimal     @db.Decimal(10, 2)
  pointsEarned    Int         @default(0)
  
  deliveryType    String
  deliveryTime    DateTime?
  comment         String?
  
  createdAt       DateTime    @default(now())
  updatedAt       DateTime    @updatedAt
  completedAt     DateTime?
  
  userId          String
  user            User        @relation(fields: [userId], references: [id])
  
  addressId       String?
  address         Address?    @relation(fields: [addressId], references: [id])
  
  storeId         String?
  store           Store?      @relation(fields: [storeId], references: [id])
  
  items           OrderItem[]
  
  @@map("orders")
}

model OrderItem {
  id          String    @id @default(uuid())
  quantity    Int
  price       Decimal   @db.Decimal(10, 2)
  total       Decimal   @db.Decimal(10, 2)
  
  orderId     String
  order       Order     @relation(fields: [orderId], references: [id], onDelete: Cascade)
  
  productId   String
  product     Product   @relation(fields: [productId], references: [id])
  
  @@map("order_items")
}

model Promotion {
  id              String        @id @default(uuid())
  title           String
  titleKy         String?
  titleRu         String?
  description     String
  descriptionKy   String?
  descriptionRu   String?
  image           String
  type            PromotionType
  
  discountPercent Int?
  cashbackPercent Int?
  
  minOrderAmount  Decimal?      @db.Decimal(10, 2)
  productIds      String[]
  
  startDate       DateTime
  endDate         DateTime
  isActive        Boolean       @default(true)
  sortOrder       Int           @default(0)
  
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt
  
  @@map("promotions")
}

model Raffle {
  id                String        @id @default(uuid())
  title             String
  titleKy           String?
  titleRu           String?
  description       String
  descriptionKy     String?
  descriptionRu     String?
  image             String
  prize             String
  
  minPointsRequired Int?
  minPurchaseAmount Decimal?      @db.Decimal(10, 2)
  
  startDate         DateTime
  endDate           DateTime
  drawDate          DateTime
  isActive          Boolean       @default(true)
  winnerId          String?
  
  createdAt         DateTime      @default(now())
  updatedAt         DateTime      @updatedAt
  
  entries           RaffleEntry[]
  
  @@map("raffles")
}

model RaffleEntry {
  id          String    @id @default(uuid())
  
  userId      String
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  raffleId    String
  raffle      Raffle    @relation(fields: [raffleId], references: [id], onDelete: Cascade)
  
  createdAt   DateTime  @default(now())
  
  @@unique([userId, raffleId])
  @@map("raffle_entries")
}

model NewsArticle {
  id          String    @id @default(uuid())
  title       String
  titleKy     String?
  titleRu     String?
  content     String
  contentKy   String?
  contentRu   String?
  image       String
  isPublished Boolean   @default(false)
  publishedAt DateTime?
  views       Int       @default(0)
  sortOrder   Int       @default(0)
  
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  
  @@map("news_articles")
}

model Favorite {
  id        String   @id @default(uuid())
  
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  productId String
  product   Product  @relation(fields: [productId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  
  @@unique([userId, productId])
  @@map("favorites")
}

model Review {
  id        String   @id @default(uuid())
  rating    Int
  comment   String?
  
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  productId String
  product   Product  @relation(fields: [productId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@map("reviews")
}

model ChatMessage {
  id        String   @id @default(uuid())
  message   String
  isFromUser Boolean @default(true)
  isRead    Boolean  @default(false)
  
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  
  @@map("chat_messages")
}

model Notification {
  id        String   @id @default(uuid())
  title     String
  titleKy   String?
  titleRu   String?
  body      String
  bodyKy    String?
  bodyRu    String?
  type      String
  data      String?
  isRead    Boolean  @default(false)
  
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  
  @@map("notifications")
}

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

**Примени миграцию:**

```bash
cd backend
npx prisma migrate dev --name complete_schema
npx prisma generate
```

---

### Шаг 2: Создание Prisma модуля

**Файл: `backend/src/prisma/prisma.service.ts`**

```typescript
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit() {
    await this.$connect();
    console.log('✅ Prisma connected to database');
  }

  async onModuleDestroy() {
    await this.$disconnect();
    console.log('❌ Prisma disconnected from database');
  }
}
```

**Файл: `backend/src/prisma/prisma.module.ts`**

```typescript
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

**Обнови `backend/src/app.module.ts`:**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
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
    PrismaModule,
    HealthModule,
  ],
})
export class AppModule {}
```

---

### Шаг 3: Создание Auth модуля

**Создай модуль Auth:**

```bash
cd backend/src
mkdir auth
cd auth
```

**Файл: `backend/src/auth/dto/send-code.dto.ts`**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsPhoneNumber } from 'class-validator';

export class SendCodeDto {
  @ApiProperty({ example: '+996700123456' })
  @IsString()
  @IsPhoneNumber('KG')
  phone: string;
}
```

**Файл: `backend/src/auth/dto/verify-code.dto.ts`**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsPhoneNumber, Length } from 'class-validator';

export class VerifyCodeDto {
  @ApiProperty({ example: '+996700123456' })
  @IsString()
  @IsPhoneNumber('KG')
  phone: string;

  @ApiProperty({ example: '1234' })
  @IsString()
  @Length(4, 4)
  code: string;
}
```

**Файл: `backend/src/auth/dto/refresh-token.dto.ts`**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}
```

**Файл: `backend/src/auth/auth.service.ts`**

```typescript
import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { SendCodeDto } from './dto/send-code.dto';
import { VerifyCodeDto } from './dto/verify-code.dto';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async sendCode(dto: SendCodeDto) {
    const code = this.generateCode();

    // TODO: Интегрировать SMS сервис (Nikita, Beeline)
    // await this.smsService.send(dto.phone, `Ваш код: ${code}`);

    // Для разработки сохраняем код в консоль
    console.log(`📱 SMS Code for ${dto.phone}: ${code}`);

    // TODO: Сохранить код в Redis с TTL 5 минут
    // await this.redis.set(`sms:${dto.phone}`, code, 'EX', 300);

    return {
      success: true,
      message: `Код отправлен на номер ${dto.phone}`,
    };
  }

  async verifyCode(dto: VerifyCodeDto) {
    // TODO: Проверить код из Redis
    // const storedCode = await this.redis.get(`sms:${dto.phone}`);
    
    // Для разработки принимаем любой код длиной 4
    if (dto.code.length !== 4) {
      throw new BadRequestException('Неверный код');
    }

    let user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          phone: dto.phone,
          qrCode: this.generateQRCode(),
        },
      });
    }

    // Обновить lastLoginAt
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const tokens = await this.generateTokens(user.id);

    return {
      user: {
        id: user.id,
        phone: user.phone,
        firstName: user.firstName,
        lastName: user.lastName,
        loyaltyPoints: user.loyaltyPoints,
        qrCode: user.qrCode,
      },
      ...tokens,
    };
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken);
      const tokens = await this.generateTokens(payload.sub);
      return tokens;
    } catch (error) {
      throw new UnauthorizedException('Невалидный refresh token');
    }
  }

  async logout(userId: string) {
    // TODO: Добавить refresh token в blacklist (Redis)
    return { success: true };
  }

  private async generateTokens(userId: string) {
    const payload = { sub: userId };

    const accessToken = this.jwtService.sign(payload, {
      expiresIn: '7d',
    });

    const refreshToken = this.jwtService.sign(payload, {
      expiresIn: '30d',
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  private generateCode(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  private generateQRCode(): string {
    return `SHR-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

**Файл: `backend/src/auth/auth.controller.ts`**

```typescript
import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { SendCodeDto } from './dto/send-code.dto';
import { VerifyCodeDto } from './dto/verify-code.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('send-code')
  @ApiOperation({ summary: 'Отправить SMS код' })
  sendCode(@Body() dto: SendCodeDto) {
    return this.authService.sendCode(dto);
  }

  @Post('verify-code')
  @ApiOperation({ summary: 'Верифицировать SMS код и войти' })
  verifyCode(@Body() dto: VerifyCodeDto) {
    return this.authService.verifyCode(dto);
  }

  @Post('refresh')
  @ApiOperation({ summary: 'Обновить access token' })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto.refreshToken);
  }

  @Post('logout')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Выход' })
  logout(@Request() req) {
    return this.authService.logout(req.user.id);
  }
}
```

**Файл: `backend/src/auth/strategies/jwt.strategy.ts`**

```typescript
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('jwt.secret'),
    });
  }

  async validate(payload: any) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException();
    }

    return {
      id: user.id,
      phone: user.phone,
      role: user.role,
    };
  }
}
```

**Файл: `backend/src/auth/guards/jwt-auth.guard.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
```

**Файл: `backend/src/auth/guards/roles.guard.ts`**

```typescript
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(
      'roles',
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some((role) => user.role === role);
  }
}
```

**Файл: `backend/src/auth/decorators/roles.decorator.ts`**

```typescript
import { SetMetadata } from '@nestjs/common';
import { UserRole } from '@prisma/client';

export const Roles = (...roles: UserRole[]) => SetMetadata('roles', roles);
```

**Файл: `backend/src/auth/decorators/current-user.decorator.ts`**

```typescript
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
```

**Файл: `backend/src/auth/auth.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get('jwt.secret'),
        signOptions: {
          expiresIn: configService.get('jwt.expiresIn'),
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}
```

**Обнови `backend/src/app.module.ts`:**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
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
    PrismaModule,
    HealthModule,
    AuthModule,
  ],
})
export class AppModule {}
```

---

### Шаг 4: Создание Users модуля

**Создай модуль Users:**

```bash
cd backend/src
mkdir users
cd users
```

**Файл: `backend/src/users/dto/update-user.dto.ts`**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsEmail, IsOptional, IsDateString } from 'class-validator';

export class UpdateUserDto {
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  firstName?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  lastName?: string;

  @ApiProperty({ required: false })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ required: false })
  @IsDateString()
  @IsOptional()
  birthDate?: string;
}
```

**Файл: `backend/src/users/users.service.ts`**

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        phone: true,
        firstName: true,
        lastName: true,
        email: true,
        avatar: true,
        birthDate: true,
        loyaltyPoints: true,
        qrCode: true,
        createdAt: true,
        role: true,
      },
    });

    if (!user) {
      throw new NotFoundException('Пользователь не найден');
    }

    return user;
  }

  async updateProfile(userId: string, dto: UpdateUserDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        email: dto.email,
        birthDate: dto.birthDate ? new Date(dto.birthDate) : undefined,
      },
      select: {
        id: true,
        phone: true,
        firstName: true,
        lastName: true,
        email: true,
        avatar: true,
        birthDate: true,
        loyaltyPoints: true,
        qrCode: true,
      },
    });
  }

  async getQRCode(userId: string) {
    const user = await this.findById(userId);
    
    // TODO: Генерировать QR код как изображение
    // const qrCodeImage = await generateQRCode(user.qrCode);

    return {
      qrCode: user.qrCode,
      qrCodeImage: null, // TODO: base64 изображение
    };
  }

  async updateFCMToken(userId: string, fcmToken: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });

    return { success: true };
  }
}
```

**Файл: `backend/src/users/users.controller.ts`**

```typescript
import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Post,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Получить текущего пользователя' })
  getMe(@CurrentUser() user: any) {
    return this.usersService.findById(user.id);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Обновить профиль' })
  updateProfile(@CurrentUser() user: any, @Body() dto: UpdateUserDto) {
    return this.usersService.updateProfile(user.id, dto);
  }

  @Get('me/qr-code')
  @ApiOperation({ summary: 'Получить QR код' })
  getQRCode(@CurrentUser() user: any) {
    return this.usersService.getQRCode(user.id);
  }

  @Post('me/fcm-token')
  @ApiOperation({ summary: 'Сохранить FCM токен' })
  updateFCMToken(@CurrentUser() user: any, @Body('token') token: string) {
    return this.usersService.updateFCMToken(user.id, token);
  }
}
```

**Файл: `backend/src/users/users.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';

@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
```

**Обнови `backend/src/app.module.ts`:**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
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
    PrismaModule,
    HealthModule,
    AuthModule,
    UsersModule,
  ],
})
export class AppModule {}
```

---

### Шаг 5: Создание seed файла с тестовыми данными

**Файл: `backend/prisma/seed.ts`**

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Создать настройки
  await prisma.settings.createMany({
    data: [
      {
        key: 'loyalty_cashback_percent',
        value: '5',
        description: 'Процент кэшбэка по программе лояльности',
      },
      {
        key: 'loyalty_max_points_use_percent',
        value: '100',
        description: 'Максимальный процент оплаты баллами',
      },
      {
        key: 'delivery_fee',
        value: '100',
        description: 'Стоимость доставки (сом)',
      },
      {
        key: 'free_delivery_min_amount',
        value: '1000',
        description: 'Минимальная сумма для бесплатной доставки',
      },
      {
        key: 'support_phone',
        value: '+996701039009',
        description: 'Телефон службы поддержки',
      },
      {
        key: 'support_email',
        value: 'support@shirin.kg',
        description: 'Email службы поддержки',
      },
    ],
    skipDuplicates: true,
  });

  // Создать тестового admin пользователя
  const admin = await prisma.user.upsert({
    where: { phone: '+996700000000' },
    update: {},
    create: {
      phone: '+996700000000',
      firstName: 'Admin',
      lastName: 'User',
      role: 'ADMIN',
      loyaltyPoints: 0,
    },
  });

  console.log('✅ Database seeded successfully!');
  console.log('👤 Admin user:', admin.phone);
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

**Обнови `backend/package.json`:**

```json
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

**Запусти seed:**

```bash
cd backend
npm install --save-dev ts-node
npx prisma db seed
```

---

### Шаг 6: Тестирование endpoints

**Проверь работу Auth:**

```bash
# Отправить SMS код
curl -X POST http://localhost:3000/api/v1/auth/send-code \
  -H "Content-Type: application/json" \
  -d '{"phone": "+996700123456"}'

# Верифицировать код (любой 4-значный)
curl -X POST http://localhost:3000/api/v1/auth/verify-code \
  -H "Content-Type: application/json" \
  -d '{"phone": "+996700123456", "code": "1234"}'

# Сохрани полученный accessToken для следующих запросов
```

**Проверь работу Users:**

```bash
# Получить текущего пользователя
curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Обновить профиль
curl -X PATCH http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"firstName": "Иван", "lastName": "Иванов"}'

# Получить QR код
curl -X GET http://localhost:3000/api/v1/users/me/qr-code \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## ✅ Критерии приемки Фазы 2

- [ ] Prisma схема с полными моделями создана
- [ ] Миграции применены успешно
- [ ] Prisma модуль работает
- [ ] Auth модуль реализован:
  - [ ] POST `/auth/send-code` работает
  - [ ] POST `/auth/verify-code` создает пользователя и возвращает токены
  - [ ] POST `/auth/refresh` обновляет токен
  - [ ] POST `/auth/logout` работает
- [ ] Users модуль реализован:
  - [ ] GET `/users/me` возвращает пользователя
  - [ ] PATCH `/users/me` обновляет профиль
  - [ ] GET `/users/me/qr-code` возвращает QR код
  - [ ] POST `/users/me/fcm-token` сохраняет токен
- [ ] JWT Guard защищает endpoints
- [ ] Swagger документация обновлена
- [ ] Seed данные созданы
- [ ] Все endpoints протестированы

---

## 📝 Коммит изменений

```bash
git add .
git commit -m "Phase 2: Backend Core - Prisma schema, Auth module (SMS), Users module, JWT Guards"
```

---

## ➡️ Следующая фаза

После завершения Фазы 2, переходи к **PHASE-3-Backend-Features.md** для реализации остальных модулей Backend (Products, Orders, Loyalty, etc.).
