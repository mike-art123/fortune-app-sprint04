-- CreateTable
CREATE TABLE "daily_fortune_usage" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "date_key" TEXT NOT NULL,
    "fortune_id" TEXT NOT NULL,
    "successful_free_usage_count" INTEGER NOT NULL DEFAULT 0,
    "last_free_used_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "daily_fortune_usage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "daily_fortune_usage_user_id_date_key_fortune_id_key" ON "daily_fortune_usage"("user_id", "date_key", "fortune_id");

-- CreateIndex
CREATE INDEX "daily_fortune_usage_user_id_date_key_idx" ON "daily_fortune_usage"("user_id", "date_key");

-- AddForeignKey
ALTER TABLE "daily_fortune_usage" ADD CONSTRAINT "daily_fortune_usage_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
