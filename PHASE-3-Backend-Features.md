# ФАЗА 3: Backend Features - Products, Orders, Loyalty, Promotions

## 🎯 Цели фазы
- Реализовать Products модуль (каталог товаров)
- Реализовать Orders модуль (заказы)
- Реализовать Loyalty модуль (программа лояльности)
- Реализовать Promotions модуль (акции)
- Реализовать Stores модуль (магазины)
- Реализовать Storage модуль (MinIO)

## ⏱ Длительность: 10-15 дней

## 📋 Предварительные требования
- Фаза 2 завершена
- Auth и Users модули работают
- JWT Guards настроены

---

## 🚀 Инструкции для Claude Code

### Шаг 1: Создание Storage модуля (MinIO)

```bash
cd backend/src
mkdir storage
```

**Файл: `backend/src/storage/storage.service.ts`**

```typescript
import { Injectable, Logger } from '@nestjs/common';
import * as Minio from 'minio';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private minioClient: Minio.Client;
  private readonly bucketName = 'shirin-files';

  constructor(private configService: ConfigService) {
    this.minioClient = new Minio.Client({
      endPoint: this.configService.get('minio.endPoint'),
      port: this.configService.get('minio.port'),
      useSSL: this.configService.get('minio.useSSL'),
      accessKey: this.configService.get('minio.accessKey'),
      secretKey: this.configService.get('minio.secretKey'),
    });

    this.ensureBucketExists();
  }

  private async ensureBucketExists() {
    try {
      const exists = await this.minioClient.bucketExists(this.bucketName);
      if (!exists) {
        await this.minioClient.makeBucket(this.bucketName, 'us-east-1');
        
        const policy = {
          Version: '2012-10-17',
          Statement: [
            {
              Effect: 'Allow',
              Principal: { AWS: ['*'] },
              Action: ['s3:GetObject'],
              Resource: [`arn:aws:s3:::${this.bucketName}/*`],
            },
          ],
        };
        
        await this.minioClient.setBucketPolicy(
          this.bucketName,
          JSON.stringify(policy),
        );
        
        this.logger.log(`✅ Bucket ${this.bucketName} created`);
      }
    } catch (error) {
      this.logger.error('Error creating bucket', error);
    }
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'general',
  ): Promise<string> {
    const fileName = `${folder}/${Date.now()}-${file.originalname}`;
    
    await this.minioClient.putObject(
      this.bucketName,
      fileName,
      file.buffer,
      file.size,
      {
        'Content-Type': file.mimetype,
      },
    );

    return this.getFileUrl(fileName);
  }

  async deleteFile(fileName: string): Promise<void> {
    await this.minioClient.removeObject(this.bucketName, fileName);
  }

  getFileUrl(fileName: string): string {
    const { endPoint, port, useSSL } = this.configService.get('minio');
    const protocol = useSSL ? 'https' : 'http';
    return `${protocol}://${endPoint}:${port}/${this.bucketName}/${fileName}`;
  }
}
```

**Файл: `backend/src/storage/storage.controller.ts`**

```typescript
import {
  Controller,
  Post,
  UseInterceptors,
  UploadedFile,
  UseGuards,
  Query,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiConsumes, ApiBearerAuth } from '@nestjs/swagger';
import { StorageService } from './storage.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Storage')
@Controller('storage')
export class StorageController {
  constructor(private storageService: StorageService) {}

  @Post('upload')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(
    @UploadedFile() file: Express.Multer.File,
    @Query('folder') folder?: string,
  ) {
    const url = await this.storageService.uploadFile(file, folder);
    return { url };
  }
}
```

**Файл: `backend/src/storage/storage.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { StorageService } from './storage.service';
import { StorageController } from './storage.controller';

@Module({
  controllers: [StorageController],
  providers: [StorageService],
  exports: [StorageService],
})
export class StorageModule {}
```

---

### Шаг 2: Создание Products модуля

```bash
cd backend/src
mkdir products
```

**Файл: `backend/src/products/dto/create-product.dto.ts`**

```typescript
import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsNumber,
  IsBoolean,
  IsOptional,
  IsArray,
  Min,
} from 'class-validator';

export class CreateProductDto {
  @ApiProperty()
  @IsString()
  name: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ required: false })
  @IsNumber()
  @IsOptional()
  discountPrice?: number;

  @ApiProperty({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  images: string[];

  @ApiProperty()
  @IsString()
  categoryId: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  ingredients?: string;

  @ApiProperty({ required: false })
  @IsNumber()
  @IsOptional()
  weight?: number;

  @ApiProperty({ required: false })
  @IsNumber()
  @IsOptional()
  calories?: number;

  @ApiProperty({ default: true })
  @IsBoolean()
  @IsOptional()
  isAvailable?: boolean;

  @ApiProperty({ default: false })
  @IsBoolean()
  @IsOptional()
  isNew?: boolean;

  @ApiProperty({ default: false })
  @IsBoolean()
  @IsOptional()
  isBestseller?: boolean;
}
```

**Файл: `backend/src/products/products.service.ts`**

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async findAll(params: {
    page?: number;
    limit?: number;
    categoryId?: string;
    search?: string;
    isNew?: boolean;
    isBestseller?: boolean;
    sort?: 'popular' | 'newest' | 'price-asc' | 'price-desc';
  }) {
    const page = params.page || 1;
    const limit = params.limit || 20;
    const skip = (page - 1) * limit;

    const where: Prisma.ProductWhereInput = {
      isAvailable: true,
      ...(params.categoryId && { categoryId: params.categoryId }),
      ...(params.isNew !== undefined && { isNew: params.isNew }),
      ...(params.isBestseller !== undefined && {
        isBestseller: params.isBestseller,
      }),
      ...(params.search && {
        OR: [
          { name: { contains: params.search, mode: 'insensitive' } },
          { description: { contains: params.search, mode: 'insensitive' } },
        ],
      }),
    };

    const orderBy: Prisma.ProductOrderByWithRelationInput[] = [];
    switch (params.sort) {
      case 'newest':
        orderBy.push({ createdAt: 'desc' });
        break;
      case 'price-asc':
        orderBy.push({ price: 'asc' });
        break;
      case 'price-desc':
        orderBy.push({ price: 'desc' });
        break;
      default:
        orderBy.push({ sortOrder: 'asc' }, { createdAt: 'desc' });
    }

    const [products, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          category: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      this.prisma.product.count({ where }),
    ]);

    return {
      data: products,
      meta: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalItems: total,
        itemsPerPage: limit,
      },
    };
  }

  async findById(id: string, userId?: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: {
        category: true,
        reviews: {
          include: {
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                avatar: true,
              },
            },
          },
          orderBy: {
            createdAt: 'desc',
          },
          take: 10,
        },
      },
    });

    if (!product) {
      throw new NotFoundException('Продукт не найден');
    }

    let isFavorite = false;
    if (userId) {
      const favorite = await this.prisma.favorite.findUnique({
        where: {
          userId_productId: {
            userId,
            productId: id,
          },
        },
      });
      isFavorite = !!favorite;
    }

    const avgRating =
      product.reviews.length > 0
        ? product.reviews.reduce((acc, r) => acc + r.rating, 0) /
          product.reviews.length
        : 0;

    return {
      ...product,
      isFavorite,
      rating: Math.round(avgRating * 10) / 10,
      reviewsCount: product.reviews.length,
    };
  }

  async getCategories() {
    const categories = await this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
    });

    return Promise.all(
      categories.map(async (category) => {
        const productsCount = await this.prisma.product.count({
          where: {
            categoryId: category.id,
            isAvailable: true,
          },
        });

        return {
          ...category,
          productsCount,
        };
      }),
    );
  }

  async toggleFavorite(userId: string, productId: string) {
    const existing = await this.prisma.favorite.findUnique({
      where: {
        userId_productId: {
          userId,
          productId,
        },
      },
    });

    if (existing) {
      await this.prisma.favorite.delete({
        where: {
          userId_productId: {
            userId,
            productId,
          },
        },
      });
      return { success: true, isFavorite: false };
    } else {
      await this.prisma.favorite.create({
        data: {
          userId,
          productId,
        },
      });
      return { success: true, isFavorite: true };
    }
  }

  async getFavorites(userId: string) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId },
      include: {
        product: {
          include: {
            category: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return {
      data: favorites.map((f) => f.product),
    };
  }

  // Admin methods
  async create(dto: CreateProductDto) {
    return this.prisma.product.create({
      data: dto,
      include: {
        category: true,
      },
    });
  }

  async update(id: string, dto: Partial<CreateProductDto>) {
    return this.prisma.product.update({
      where: { id },
      data: dto,
      include: {
        category: true,
      },
    });
  }

  async delete(id: string) {
    await this.prisma.product.delete({
      where: { id },
    });
    return { success: true };
  }
}
```

**Файл: `backend/src/products/products.controller.ts`**

```typescript
import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ProductsService } from './products.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  constructor(private productsService: ProductsService) {}

  @Get()
  @ApiOperation({ summary: 'Получить список продуктов' })
  findAll(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('categoryId') categoryId?: string,
    @Query('search') search?: string,
    @Query('isNew') isNew?: boolean,
    @Query('isBestseller') isBestseller?: boolean,
    @Query('sort') sort?: 'popular' | 'newest' | 'price-asc' | 'price-desc',
  ) {
    return this.productsService.findAll({
      page,
      limit,
      categoryId,
      search,
      isNew,
      isBestseller,
      sort,
    });
  }

  @Get('categories')
  @ApiOperation({ summary: 'Получить список категорий' })
  getCategories() {
    return this.productsService.getCategories();
  }

  @Get('favorites')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Получить избранные продукты' })
  getFavorites(@CurrentUser() user: any) {
    return this.productsService.getFavorites(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Получить детали продукта' })
  findById(@Param('id') id: string, @CurrentUser() user?: any) {
    return this.productsService.findById(id, user?.id);
  }

  @Post(':id/favorite')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Добавить/удалить из избранного' })
  toggleFavorite(@Param('id') id: string, @CurrentUser() user: any) {
    return this.productsService.toggleFavorite(user.id, id);
  }

  @Delete(':id/favorite')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Удалить из избранного' })
  removeFavorite(@Param('id') id: string, @CurrentUser() user: any) {
    return this.productsService.toggleFavorite(user.id, id);
  }
}
```

**Файл: `backend/src/products/products.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';

@Module({
  controllers: [ProductsController],
  providers: [ProductsService],
  exports: [ProductsService],
})
export class ProductsModule {}
```

---

### Шаг 3: Обновление seed файла с данными

**Обнови `backend/prisma/seed.ts` (добавь в конец main функции):**

```typescript
// ... предыдущий код ...

  // Создать категории
  const categories = await Promise.all([
    prisma.category.upsert({
      where: { name: 'Торты' },
      update: {},
      create: {
        name: 'Торты',
        nameRu: 'Торты',
        nameKy: 'Тортор',
        description: 'Свежие торты на любой вкус',
        icon: '🎂',
        sortOrder: 1,
      },
    }),
    prisma.category.upsert({
      where: { name: 'Пирожные' },
      update: {},
      create: {
        name: 'Пирожные',
        nameRu: 'Пирожные',
        nameKy: 'Пирогдор',
        description: 'Изысканные пирожные',
        icon: '🧁',
        sortOrder: 2,
      },
    }),
    prisma.category.upsert({
      where: { name: 'Печенье' },
      update: {},
      create: {
        name: 'Печенье',
        nameRu: 'Печенье',
        nameKy: 'Печенье',
        description: 'Хрустящее печенье',
        icon: '🍪',
        sortOrder: 3,
      },
    }),
    prisma.category.upsert({
      where: { name: 'Эклеры' },
      update: {},
      create: {
        name: 'Эклеры',
        nameRu: 'Эклеры',
        nameKy: 'Эклерлер',
        description: 'Воздушные эклеры',
        icon: '🥐',
        sortOrder: 4,
      },
    }),
  ]);

  // Создать товары
  await Promise.all([
    prisma.product.upsert({
      where: { name: 'Наполеон' },
      update: {},
      create: {
        name: 'Наполеон',
        nameRu: 'Наполеон',
        description: 'Классический торт со сливочным кремом',
        price: 1200,
        discountPrice: 999,
        images: [
          'https://via.placeholder.com/400x300.png?text=Napoleon',
        ],
        categoryId: categories[0].id,
        weight: 1000,
        calories: 350,
        isAvailable: true,
        isBestseller: true,
      },
    }),
    prisma.product.upsert({
      where: { name: 'Медовик' },
      update: {},
      create: {
        name: 'Медовик',
        nameRu: 'Медовик',
        description: 'Нежный медовый торт',
        price: 1100,
        images: [
          'https://via.placeholder.com/400x300.png?text=Medovik',
        ],
        categoryId: categories[0].id,
        weight: 1000,
        calories: 320,
        isAvailable: true,
        isNew: true,
      },
    }),
    prisma.product.upsert({
      where: { name: 'Эклер шоколадный' },
      update: {},
      create: {
        name: 'Эклер шоколадный',
        nameRu: 'Эклер шоколадный',
        description: 'Эклер с шоколадным кремом',
        price: 150,
        images: [
          'https://via.placeholder.com/400x300.png?text=Eclair',
        ],
        categoryId: categories[3].id,
        weight: 80,
        calories: 280,
        isAvailable: true,
        isBestseller: true,
      },
    }),
  ]);

  // Создать магазины
  await prisma.store.upsert({
    where: { name: 'Ширин - Центр' },
    update: {},
    create: {
      name: 'Ширин - Центр',
      nameRu: 'Ширин - Центр',
      address: 'ул. Чуй 100, Бишкек',
      addressRu: 'ул. Чуй 100, Бишкек',
      latitude: 42.8746,
      longitude: 74.5698,
      phone: '+996700000001',
      workHours: JSON.stringify({
        mon: '9:00-21:00',
        tue: '9:00-21:00',
        wed: '9:00-21:00',
        thu: '9:00-21:00',
        fri: '9:00-21:00',
        sat: '10:00-20:00',
        sun: '10:00-20:00',
      }),
    },
  });

  console.log('✅ Categories:', categories.length);
  console.log('✅ Test products created');
  console.log('✅ Test store created');

// ... остальной код ...
```

**Запусти seed:**

```bash
npx prisma db seed
```

---

### Шаг 4: Обновление app.module.ts

**Файл: `backend/src/app.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { StorageModule } from './storage/storage.module';
import { ProductsModule } from './products/products.module';
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
    StorageModule,
    ProductsModule,
  ],
})
export class AppModule {}
```

---

### Шаг 5: Тестирование Products API

```bash
# Получить категории
curl http://localhost:3000/api/v1/products/categories

# Получить список продуктов
curl "http://localhost:3000/api/v1/products?page=1&limit=10"

# Получить продукты категории
curl "http://localhost:3000/api/v1/products?categoryId=CATEGORY_ID"

# Получить детали продукта
curl http://localhost:3000/api/v1/products/PRODUCT_ID

# Добавить в избранное (требуется токен)
curl -X POST http://localhost:3000/api/v1/products/PRODUCT_ID/favorite \
  -H "Authorization: Bearer YOUR_TOKEN"

# Получить избранные (требуется токен)
curl http://localhost:3000/api/v1/products/favorites \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## ✅ Критерии приемки Фазы 3 (часть 1)

- [ ] Storage модуль создан и подключен к MinIO
- [ ] Products модуль реализован:
  - [ ] GET `/products` - список продуктов с фильтрацией
  - [ ] GET `/products/:id` - детали продукта
  - [ ] GET `/products/categories` - категории
  - [ ] POST `/products/:id/favorite` - добавить в избранное
  - [ ] GET `/products/favorites` - список избранных
- [ ] Seed данные с категориями и товарами созданы
- [ ] Все endpoints протестированы
- [ ] Swagger документация обновлена

---

## 📝 Коммит изменений

```bash
git add .
git commit -m "Phase 3 (part 1): Storage module (MinIO), Products module with favorites"
```

---

## ➡️ Продолжение

Это первая часть Фазы 3. Продолжай с реализацией Orders, Loyalty, Promotions и других модулей согласно плану.

**Следующие модули для реализации:**
1. Orders модуль (заказы)
2. Loyalty модуль (программа лояльности)
3. Promotions модуль (акции)
4. Stores модуль (магазины)
5. Chat модуль (WebSocket)
6. Notifications модуль

Каждый модуль создавай по аналогии с Products модулем, следуя структуре:
- DTOs
- Service с бизнес-логикой
- Controller с endpoints
- Module для связывания
- Обновление app.module.ts

После завершения всех Backend модулей переходи к **PHASE-4-Mobile-Setup.md**.
