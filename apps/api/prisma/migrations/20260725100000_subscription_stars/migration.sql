-- AlterTable
ALTER TABLE "subscriptions" ADD COLUMN     "auto_renew" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "platform_transaction_id" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_platform_transaction_id_key" ON "subscriptions"("platform_transaction_id");
