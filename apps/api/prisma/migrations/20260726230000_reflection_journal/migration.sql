-- CreateTable
CREATE TABLE "reflection_entries" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "reading_id" TEXT,
    "feeling" TEXT NOT NULL,
    "note" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "reflection_entries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "reflection_entries_user_id_reading_id_key" ON "reflection_entries"("user_id", "reading_id");

-- CreateIndex
CREATE INDEX "reflection_entries_user_id_created_at_idx" ON "reflection_entries"("user_id", "created_at");

-- AddForeignKey
ALTER TABLE "reflection_entries" ADD CONSTRAINT "reflection_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
