-- CreateTable
CREATE TABLE "ghazals" (
    "id" TEXT NOT NULL,
    "number" INTEGER NOT NULL,
    "opening_line" TEXT NOT NULL,
    "verses" TEXT NOT NULL,
    "edition" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ghazals_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ghazals_edition_number_key" ON "ghazals"("edition", "number");
