-- AlterEnum
ALTER TYPE "UserRole" ADD VALUE 'STORE_STAFF';

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "externalId" TEXT,
ADD COLUMN     "storeId" TEXT;

-- AlterTable
ALTER TABLE "categories" ADD COLUMN     "externalId" TEXT;

-- AlterTable
ALTER TABLE "products" ADD COLUMN     "externalId" TEXT;

-- AlterTable
ALTER TABLE "stores" ADD COLUMN     "externalId" TEXT;

-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "externalId" TEXT;

-- CreateTable
CREATE TABLE "integration_events" (
    "id" BIGSERIAL NOT NULL,
    "type" TEXT NOT NULL,
    "aggregateId" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "integration_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "integration_events_type_id_idx" ON "integration_events"("type", "id");

-- CreateIndex
CREATE UNIQUE INDEX "users_externalId_key" ON "users"("externalId");

-- CreateIndex
CREATE UNIQUE INDEX "categories_externalId_key" ON "categories"("externalId");

-- CreateIndex
CREATE UNIQUE INDEX "products_externalId_key" ON "products"("externalId");

-- CreateIndex
CREATE UNIQUE INDEX "stores_externalId_key" ON "stores"("externalId");

-- CreateIndex
CREATE UNIQUE INDEX "orders_externalId_key" ON "orders"("externalId");

-- CreateIndex
CREATE INDEX "orders_storeId_status_createdAt_idx" ON "orders"("storeId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "orders_updatedAt_idx" ON "orders"("updatedAt");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "stores"("id") ON DELETE SET NULL ON UPDATE CASCADE;

