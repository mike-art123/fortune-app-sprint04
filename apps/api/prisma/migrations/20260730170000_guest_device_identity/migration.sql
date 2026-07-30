-- Guest identity for the Play build: users may anchor on a device id instead
-- of a Telegram id, so telegram_id becomes optional and device_id arrives as
-- a second unique anchor.

-- AlterTable
ALTER TABLE "users" ADD COLUMN "device_id" TEXT,
ALTER COLUMN "telegram_id" DROP NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "users_device_id_key" ON "users"("device_id");
