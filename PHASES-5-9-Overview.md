# ФАЗЫ 5-9: Краткий обзор и ключевые инструкции

## ФАЗА 5: Mobile Core Features (10-12 дней)

### Цели
- Auth UI (Phone input, SMS verification)
- Home screen (Categories, products)
- Product catalog with filters
- Product details
- Cart and Checkout
- Profile screen

### Ключевые задачи для Claude Code

#### 1. Auth Screens
```bash
# Создай экраны
lib/features/auth/presentation/pages/phone_input_page.dart
lib/features/auth/presentation/pages/sms_verification_page.dart
lib/features/auth/presentation/widgets/phone_input_field.dart
lib/features/auth/presentation/widgets/code_input_field.dart
```

**Что реализовать:**
- Phone input с маской +996 XXX XXX XXX
- SMS code input (4 цифры)
- Таймер повторной отправки (60 секунд)
- Loading состояния
- Error handling
- BLoC integration

#### 2. Home Feature
```bash
# Создай структуру
mkdir -p lib/features/home/data
mkdir -p lib/features/home/domain
mkdir -p lib/features/home/presentation/{bloc,pages,widgets}

# Создай файлы
lib/features/home/presentation/pages/home_page.dart
lib/features/home/presentation/widgets/promo_banner.dart
lib/features/home/presentation/widgets/category_grid.dart
lib/features/home/presentation/widgets/product_card.dart
```

**Что реализовать:**
- AppBar с уведомлениями
- Carousel промо-баннеров
- Grid категорий (2 колонки)
- Horizontal список новинок
- Bottom Navigation Bar (Home, Catalog, Cart, Profile)

#### 3. Products Feature
```bash
# Создай структуру
mkdir -p lib/features/products/data/{models,datasources,repositories}
mkdir -p lib/features/products/domain/{entities,repositories,usecases}
mkdir -p lib/features/products/presentation/{bloc,pages,widgets}

# Ключевые файлы
lib/features/products/presentation/pages/products_list_page.dart
lib/features/products/presentation/pages/product_details_page.dart
lib/features/products/presentation/widgets/product_card.dart
lib/features/products/presentation/widgets/filter_bottom_sheet.dart
```

**Что реализовать:**
- Список товаров с пагинацией (Infinite scroll)
- Фильтры (категория, цена, новинки)
- Поиск
- Сортировка
- Детали товара с галереей изображений
- Кнопка "В корзину"
- Кнопка "В избранное"

#### 4. Cart Feature
```bash
# Создай структуру
lib/features/cart/data/datasources/cart_local_datasource.dart
lib/features/cart/presentation/bloc/cart_bloc.dart
lib/features/cart/presentation/pages/cart_page.dart
lib/features/cart/presentation/widgets/cart_item_card.dart
```

**Что реализовать:**
- Локальное хранение корзины (SharedPreferences)
- Добавление/удаление товаров
- Изменение количества (+/-)
- Подсчет итоговой суммы
- Переход к оформлению заказа

---

## ФАЗА 6: Mobile Additional Features (8-10 дней)

### Цели
- Orders (история, детали, статусы)
- Loyalty card с QR кодом
- Promotions list
- Stores map
- Chat support
- Push notifications

### Ключевые задачи для Claude Code

#### 1. Orders Feature
```bash
lib/features/orders/presentation/pages/orders_list_page.dart
lib/features/orders/presentation/pages/order_details_page.dart
lib/features/orders/presentation/widgets/order_card.dart
lib/features/orders/presentation/widgets/order_status_timeline.dart
```

**Реализуй:**
- История заказов с фильтрами
- Детали заказа с timeline статусов
- Отмена заказа
- Повторный заказ

#### 2. Loyalty Feature
```bash
lib/features/loyalty/presentation/pages/loyalty_card_page.dart
lib/features/loyalty/presentation/widgets/qr_code_widget.dart
lib/features/loyalty/presentation/pages/points_history_page.dart
```

**Реализуй:**
- Отображение QR кода (qr_flutter)
- Баланс баллов с анимацией
- История начислений/списаний

#### 3. Stores Feature
```bash
lib/features/stores/presentation/pages/stores_map_page.dart
lib/features/stores/presentation/pages/store_details_page.dart
```

**Реализуй:**
- Google Maps с маркерами магазинов
- Определение текущего местоположения
- Построение маршрута до магазина
- Звонок в магазин (url_launcher)

#### 4. Notifications Setup
```bash
lib/core/services/notification_service.dart
lib/core/services/firebase_service.dart
```

**Реализуй:**
- Firebase setup (iOS и Android)
- Получение FCM токена
- Обработка foreground/background notifications
- Local notifications для foreground

---

## ФАЗА 7: Admin Dashboard (10-12 дней)

### Цели
- React admin панель
- Dashboard со статистикой
- CRUD товаров, заказов, пользователей
- Управление акциями
- Чат с клиентами

### Ключевые задачи для Claude Code

#### 1. Layout и Auth
```bash
cd admin-dashboard

# Установи зависимости
npm install react-router-dom axios @tanstack/react-query zustand
npm install react-hook-form zod @hookform/resolvers
npm install recharts date-fns
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Создай структуру
mkdir -p src/components/{layout,common}
mkdir -p src/pages/{Dashboard,Products,Orders,Users}
mkdir -p src/services
mkdir -p src/store
mkdir -p src/types
```

**Создай файлы:**
```typescript
// src/services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:3000/api/v1',
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
```

```typescript
// src/components/layout/Sidebar.tsx
// Меню навигации

// src/components/layout/Header.tsx
// Шапка с поиском и профилем

// src/pages/Dashboard/Dashboard.tsx
// Главная страница со статистикой
```

#### 2. Products Management
```typescript
// src/pages/Products/ProductsList.tsx
// Таблица товаров с поиском, фильтрами, пагинацией

// src/pages/Products/ProductForm.tsx
// Форма создания/редактирования товара
// React Hook Form + Zod validation
// Загрузка изображений (react-dropzone)
```

#### 3. Orders Management
```typescript
// src/pages/Orders/OrdersList.tsx
// Список заказов с фильтрами

// src/pages/Orders/OrderDetails.tsx
// Детали заказа
// Изменение статуса
// История изменений
```

#### 4. Dashboard Stats
```typescript
// src/pages/Dashboard/Dashboard.tsx
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip } from 'recharts';

// 4 карточки статистики:
// - Продажи за сегодня
// - Количество заказов
// - Активные клиенты
// - Средний чек

// График продаж за последние 30 дней
```

---

## ФАЗА 8: Integration & Testing (7-10 дней)

### Цели
- E2E тестирование
- Интеграционное тестирование
- Исправление багов
- Оптимизация производительности

### Ключевые задачи для Claude Code

#### 1. Backend Tests
```bash
cd backend

# Unit tests для всех сервисов
npm run test

# E2E tests
npm run test:e2e

# Coverage
npm run test:cov
```

**Создай тесты:**
```typescript
// src/auth/auth.service.spec.ts
describe('AuthService', () => {
  it('should send SMS code', async () => {
    // test implementation
  });
  
  it('should verify code and create user', async () => {
    // test implementation
  });
});

// test/auth.e2e-spec.ts
describe('Auth (e2e)', () => {
  it('/auth/send-code (POST)', () => {
    return request(app.getHttpServer())
      .post('/api/v1/auth/send-code')
      .send({ phone: '+996700000000' })
      .expect(201);
  });
});
```

#### 2. Mobile Tests
```bash
cd mobile

# Widget tests
flutter test

# Integration tests
flutter test integration_test/
```

**Создай тесты:**
```dart
// test/features/auth/presentation/bloc/auth_bloc_test.dart
void main() {
  group('AuthBloc', () {
    test('emits [Loading, Success] when SendCode succeeds', () async {
      // test implementation
    });
  });
}

// integration_test/app_test.dart
void main() {
  testWidgets('Complete purchase flow', (tester) async {
    // test implementation
  });
}
```

#### 3. Performance Optimization

**Backend:**
- Добавь индексы в БД для часто запрашиваемых полей
- Настрой connection pooling в Prisma
- Добавь Redis кэширование для категорий и настроек
- Оптимизируй N+1 queries

**Mobile:**
- Используй Shimmer для loading состояний
- Реализуй image caching (cached_network_image)
- Оптимизируй списки (ListView.builder с key)
- Минимизируй rebuilds (const constructors, memo)

---

## ФАЗА 9: Deployment & Release (5-7 дней)

### Цели
- Подготовка к production
- Настройка CI/CD
- Деплой backend и admin
- Публикация в сторы

### Ключевые задачи для Claude Code

#### 1. Backend Production Setup

**Создай production Dockerfile:**
```dockerfile
# backend/Dockerfile.prod
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY package*.json ./

ENV NODE_ENV=production
EXPOSE 3000
CMD ["npm", "run", "start:prod"]
```

**Создай docker-compose.prod.yml:**
```yaml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    restart: always
    environment:
      NODE_ENV: production
      DATABASE_URL: ${DATABASE_URL}
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - backend
```

#### 2. GitHub Actions CI/CD

**Создай `.github/workflows/backend.yml`:**
```yaml
name: Backend CI/CD

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: cd backend && npm ci
      - run: cd backend && npm test
      - run: cd backend && npm run test:e2e

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: docker/build-push-action@v4
        with:
          context: ./backend
          push: true
          tags: registry.example.com/shirin-backend:latest
```

#### 3. Mobile App Store Preparation

**Android (Google Play):**
```bash
# Создай keystore
keytool -genkey -v -keystore shirin-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias shirin

# Обнови android/app/build.gradle
android {
    signingConfigs {
        release {
            storeFile file("../../shirin-release.jks")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias "shirin"
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}

# Собери release AAB
flutter build appbundle --release
```

**iOS (App Store):**
```bash
# В Xcode настрой:
# - Bundle Identifier
# - Team
# - Signing & Capabilities

# Собери IPA
flutter build ipa --release
```

**Создай store assets:**
- Иконка приложения (1024x1024)
- Screenshots (разные размеры экранов)
- Feature graphic
- Privacy Policy
- Terms of Service

#### 4. Мониторинг и логирование

**Настрой Sentry:**
```typescript
// backend/src/main.ts
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
});
```

```dart
// mobile/lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
    },
    appRunner: () => runApp(ShirinApp()),
  );
}
```

---

## 📊 Сводная таблица фаз

| Фаза | Название | Длительность | Ключевые результаты |
|------|----------|--------------|---------------------|
| 1 | Infrastructure | 3-5 дней | Docker, PostgreSQL, MinIO, Redis |
| 2 | Backend Core | 7-10 дней | Prisma, Auth, Users |
| 3 | Backend Features | 10-15 дней | Products, Orders, Loyalty |
| 4 | Mobile Setup | 5-7 дней | Flutter архитектура, Auth |
| 5 | Mobile Core | 10-12 дней | Home, Products, Cart, Profile |
| 6 | Mobile Additional | 8-10 дней | Orders, Loyalty, Stores, Chat |
| 7 | Admin Dashboard | 10-12 дней | React admin панель |
| 8 | Testing | 7-10 дней | Unit, E2E, Integration тесты |
| 9 | Deployment | 5-7 дней | CI/CD, Production, App Stores |

**Итого: 65-88 дней (2.5-3.5 месяца)**

---

## 🎯 Критерии готовности к релизу

### Backend
- [ ] Все API endpoints реализованы
- [ ] Unit тесты покрытие >80%
- [ ] E2E тесты для критичных flows
- [ ] Swagger документация полная
- [ ] Логирование настроено
- [ ] Error handling корректный
- [ ] Performance оптимизирован
- [ ] Security проверен

### Mobile
- [ ] Все экраны реализованы
- [ ] Нет критичных багов
- [ ] Push уведомления работают
- [ ] Deep links настроены
- [ ] Оффлайн режим (где нужно)
- [ ] Loading states везде
- [ ] Error handling везде
- [ ] Локализация (RU, KY)
- [ ] App icons и splash screen
- [ ] Store screenshots готовы

### Admin
- [ ] Все CRUD операции работают
- [ ] Dashboard со статистикой
- [ ] Responsive дизайн
- [ ] Правильная обработка ошибок
- [ ] Роли и права доступа

### Infrastructure
- [ ] Docker containers работают стабильно
- [ ] Database backups настроены
- [ ] SSL сертификаты установлены
- [ ] Мониторинг настроен
- [ ] CI/CD pipeline работает
- [ ] Rollback plan есть

---

## 📝 Финальный чеклист перед релизом

1. **Тестирование:**
   - [ ] Все API endpoints протестированы
   - [ ] Mobile app протестирован на реальных устройствах
   - [ ] Admin панель протестирована
   - [ ] Load testing проведен

2. **Документация:**
   - [ ] API документация актуальна
   - [ ] README files обновлены
   - [ ] Deployment guide создан
   - [ ] User manual готов

3. **Security:**
   - [ ] Все секреты в environment variables
   - [ ] HTTPS настроен
   - [ ] Rate limiting настроен
   - [ ] Input validation везде
   - [ ] SQL injection защита (Prisma)

4. **Monitoring:**
   - [ ] Error tracking (Sentry)
   - [ ] Performance monitoring
   - [ ] Logs aggregation
   - [ ] Uptime monitoring

5. **Stores:**
   - [ ] Google Play Console настроен
   - [ ] App Store Connect настроен
   - [ ] Privacy Policy опубликована
   - [ ] Terms of Service опубликованы
   - [ ] Screenshots загружены

---

## 🚀 Запуск в Production

1. **Backend:**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

2. **Mobile:**
   ```bash
   # Android
   flutter build appbundle --release
   # Upload to Google Play Console
   
   # iOS
   flutter build ipa --release
   # Upload to App Store Connect via Xcode
   ```

3. **Admin:**
   ```bash
   cd admin-dashboard
   npm run build
   # Deploy to hosting (Vercel, Netlify, etc.)
   ```

---

## 📞 Поддержка после релиза

- Мониторинг ошибок через Sentry
- Анализ crash reports из сторов
- Сбор feedback от пользователей
- Регулярные обновления (bug fixes, features)
- Поддержка пользователей через чат

**Успешного запуска! 🎉**
