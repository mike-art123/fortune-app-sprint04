-- CreateTable
CREATE TABLE "ai_summary_cache" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "range_key" TEXT NOT NULL,
    "fingerprint" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'rules',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ai_summary_cache_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ai_summary_cache_user_id_range_key_key" ON "ai_summary_cache"("user_id", "range_key");

-- AddForeignKey
ALTER TABLE "ai_summary_cache" ADD CONSTRAINT "ai_summary_cache_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
