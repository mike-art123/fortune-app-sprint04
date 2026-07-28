-- AlterTable
ALTER TABLE "readings" ADD COLUMN "saved_at" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "readings_user_id_saved_at_idx" ON "readings"("user_id", "saved_at");
