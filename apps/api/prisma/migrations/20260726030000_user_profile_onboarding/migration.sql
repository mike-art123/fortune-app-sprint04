-- CreateEnum
CREATE TYPE "BirthMonth" AS ENUM ('FARVARDIN', 'ORDIBEHESHT', 'KHORDAD', 'TIR', 'MORDAD', 'SHAHRIVAR', 'MEHR', 'ABAN', 'AZAR', 'DEY', 'BAHMAN', 'ESFAND');

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "birth_month" "BirthMonth",
ADD COLUMN     "onboarding_completed" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "onboarding_completed_at" TIMESTAMP(3),
ADD COLUMN     "profile_version" INTEGER NOT NULL DEFAULT 0;
