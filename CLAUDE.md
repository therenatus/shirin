# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shirin App is a mobile application system for "Ширин" confectionery, consisting of three components:
- **Backend**: NestJS API with PostgreSQL, Prisma, Redis, MinIO
- **Mobile**: Flutter app with BLoC state management and Clean Architecture
- **Admin Dashboard**: React with TypeScript, Zustand, TanStack Query, Tailwind CSS

The project is structured in 9 development phases documented in PHASE-*.md files.

## Development Phases

Follow the phase documents in order:
1. `PHASE-1-Infrastructure.md` - Docker, PostgreSQL, MinIO, Redis setup
2. `PHASE-2-Backend-Core.md` - Prisma schema, Auth (SMS), Users, JWT Guards
3. `PHASE-3-Backend-Features.md` - Products, Orders, Loyalty, Promotions, Storage
4. `PHASE-4-Mobile-Setup.md` - Flutter architecture, themes, DI, Auth feature
5. `PHASES-5-9-Overview.md` - Mobile UI, Admin Dashboard, Testing, Deployment

## Project Structure (Target)

```
shirin-app/
├── backend/                 # NestJS API
│   ├── src/
│   │   ├── auth/           # SMS authentication
│   │   ├── users/          # User management
│   │   ├── products/       # Product catalog
│   │   ├── orders/         # Order management
│   │   ├── loyalty/        # Loyalty program
│   │   ├── promotions/     # Promotions/offers
│   │   ├── stores/         # Store locations
│   │   ├── storage/        # MinIO integration
│   │   ├── chat/           # WebSocket chat
│   │   └── notifications/  # Push notifications
│   └── prisma/schema.prisma
├── mobile/                  # Flutter app
│   └── lib/
│       ├── core/           # Network, DI, constants
│       ├── features/       # Feature modules (Clean Architecture)
│       └── shared/         # Shared widgets
├── admin-dashboard/         # React admin panel
└── docker-compose.yml
```

## Commands

### Backend (NestJS)
```bash
cd backend
npm install                    # Install dependencies
npm run start:dev             # Development server
npm test                      # Unit tests
npm run test:e2e              # E2E tests
npm run test:cov              # Coverage report
npx prisma migrate dev        # Apply migrations
npx prisma generate           # Generate Prisma client
npx prisma db seed            # Seed database
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get               # Install dependencies
flutter run                   # Run on device/emulator
flutter test                  # Widget tests
flutter test integration_test/ # Integration tests
flutter build appbundle --release  # Android release
flutter build ipa --release   # iOS release
```

### Admin Dashboard (React)
```bash
cd admin-dashboard
npm install                   # Install dependencies
npm start                     # Development server
npm test                      # Unit tests
npm run build                 # Production build
```

### Docker
```bash
docker-compose up -d          # Start all services
docker-compose logs -f backend # View backend logs
docker-compose down           # Stop all services
```

## Architecture Patterns

### Backend
- NestJS modules with controllers, services, DTOs
- Prisma ORM with PostgreSQL
- JWT authentication with SMS verification
- Global validation pipe with class-validator
- Swagger documentation at `/api/docs`
- API prefix: `/api/v1`

### Mobile (Flutter)
- Clean Architecture: data → domain → presentation layers
- BLoC pattern for state management
- GetIt for dependency injection
- Dio for HTTP with interceptors (token refresh)
- Feature-based folder structure

### Admin Dashboard
- React with TypeScript
- Zustand for state management
- TanStack Query for data fetching
- React Hook Form + Zod for forms
- Tailwind CSS for styling

## Theme/Branding

Primary color palette (from Shirin logo):
- Primary: `#D81B60` (pink-raspberry)
- Primary Dark: `#C2185B`
- Primary Light: `#FF5C8D`
- Background: `#FFF5F7` (light pink)

## Localization

Supported languages: Russian (RU - primary), Kyrgyz (KY)

Database fields with translations follow the pattern:
- `name`, `nameRu`, `nameKy`
- `description`, `descriptionRu`, `descriptionKy`

## Service Ports

- Backend API: `http://localhost:3000/api/v1`
- Swagger Docs: `http://localhost:3000/api/docs`
- Admin Dashboard: `http://localhost:3001`
- MinIO Console: `http://localhost:9001`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`
