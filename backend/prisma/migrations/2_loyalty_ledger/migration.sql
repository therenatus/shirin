-- CreateEnum
CREATE TYPE "LoyaltyTxType" AS ENUM ('EARN', 'REDEEM', 'REFUND', 'ADJUST', 'REVERSAL', 'FREE_COFFEE');

-- CreateEnum
CREATE TYPE "LoyaltyTxSource" AS ENUM ('APP_ORDER', 'IN_STORE', 'ONE_C', 'MANUAL');

-- CreateTable
CREATE TABLE "loyalty_transactions" (
    "id" TEXT NOT NULL,
    "type" "LoyaltyTxType" NOT NULL,
    "source" "LoyaltyTxSource" NOT NULL,
    "points" INTEGER NOT NULL,
    "balanceAfter" INTEGER,
    "description" TEXT,
    "userId" TEXT NOT NULL,
    "orderId" TEXT,
    "storeId" TEXT,
    "staffId" TEXT,
    "receiptNumber" TEXT,
    "receiptAmount" DECIMAL(10,2),
    "reversalOfId" TEXT,
    "externalId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "loyalty_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "loyalty_transactions_reversalOfId_key" ON "loyalty_transactions"("reversalOfId");

-- CreateIndex
CREATE UNIQUE INDEX "loyalty_transactions_externalId_key" ON "loyalty_transactions"("externalId");

-- CreateIndex
CREATE INDEX "loyalty_transactions_userId_createdAt_idx" ON "loyalty_transactions"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "loyalty_transactions_storeId_createdAt_idx" ON "loyalty_transactions"("storeId", "createdAt");

-- CreateIndex
CREATE INDEX "loyalty_transactions_staffId_createdAt_idx" ON "loyalty_transactions"("staffId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "loyalty_transactions_storeId_receiptNumber_type_key" ON "loyalty_transactions"("storeId", "receiptNumber", "type");

-- AddForeignKey
ALTER TABLE "loyalty_transactions" ADD CONSTRAINT "loyalty_transactions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loyalty_transactions" ADD CONSTRAINT "loyalty_transactions_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loyalty_transactions" ADD CONSTRAINT "loyalty_transactions_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "stores"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loyalty_transactions" ADD CONSTRAINT "loyalty_transactions_staffId_fkey" FOREIGN KEY ("staffId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loyalty_transactions" ADD CONSTRAINT "loyalty_transactions_reversalOfId_fkey" FOREIGN KEY ("reversalOfId") REFERENCES "loyalty_transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- Backfill the ledger from existing orders so history is not lost
INSERT INTO "loyalty_transactions" ("id", "type", "source", "points", "description", "userId", "orderId", "storeId", "createdAt")
SELECT gen_random_uuid()::text, 'REDEEM', 'APP_ORDER', -o."pointsUsed",
       'Списание за заказ ' || o."orderNumber", o."userId", o."id", o."storeId", o."createdAt"
FROM "orders" o
WHERE o."pointsUsed" > 0;

INSERT INTO "loyalty_transactions" ("id", "type", "source", "points", "description", "userId", "orderId", "storeId", "createdAt")
SELECT gen_random_uuid()::text, 'REFUND', 'APP_ORDER', o."pointsUsed",
       'Возврат баллов за заказ ' || o."orderNumber", o."userId", o."id", o."storeId", o."updatedAt"
FROM "orders" o
WHERE o."pointsUsed" > 0 AND o."status" = 'CANCELLED';

INSERT INTO "loyalty_transactions" ("id", "type", "source", "points", "description", "userId", "orderId", "storeId", "createdAt")
SELECT gen_random_uuid()::text, 'EARN', 'APP_ORDER', o."pointsEarned",
       'Кешбэк за заказ ' || o."orderNumber", o."userId", o."id", o."storeId",
       COALESCE(o."completedAt", o."updatedAt")
FROM "orders" o
WHERE o."pointsEarned" > 0 AND o."status" = 'DELIVERED';

-- Opening balance: whatever the order history does not explain (seeded or
-- manually set points), so that the ledger sums to the current balance
INSERT INTO "loyalty_transactions" ("id", "type", "source", "points", "balanceAfter", "description", "userId", "createdAt")
SELECT gen_random_uuid()::text, 'ADJUST', 'MANUAL', u."loyaltyPoints" - COALESCE(l.total, 0), NULL,
       'Начальный остаток', u."id", u."createdAt"
FROM "users" u
LEFT JOIN (
  SELECT "userId", SUM("points") AS total FROM "loyalty_transactions" GROUP BY "userId"
) l ON l."userId" = u."id"
WHERE u."loyaltyPoints" - COALESCE(l.total, 0) <> 0;
