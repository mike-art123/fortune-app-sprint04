-- CreateTable
CREATE TABLE "ad_mediation_sessions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "fortune_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'created',
    "provider_order" TEXT NOT NULL,
    "current_provider" TEXT,
    "attempt_count" INTEGER NOT NULL DEFAULT 0,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ad_mediation_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ad_provider_attempts" (
    "id" TEXT NOT NULL,
    "mediation_session_id" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "provider_session_id" TEXT,
    "attempt_number" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'created',
    "failure_reason" TEXT,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMP(3),
    "verified_at" TIMESTAMP(3),

    CONSTRAINT "ad_provider_attempts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rewarded_ad_entitlements" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "fortune_id" TEXT NOT NULL,
    "mediation_session_id" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "provider_reward_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'available',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "consumed_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rewarded_ad_entitlements_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ad_mediation_sessions_user_id_idempotency_key_key" ON "ad_mediation_sessions"("user_id", "idempotency_key");

-- CreateIndex
CREATE INDEX "ad_mediation_sessions_user_id_created_at_idx" ON "ad_mediation_sessions"("user_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "ad_provider_attempts_mediation_session_id_attempt_number_key" ON "ad_provider_attempts"("mediation_session_id", "attempt_number");

-- CreateIndex
CREATE INDEX "ad_provider_attempts_mediation_session_id_idx" ON "ad_provider_attempts"("mediation_session_id");

-- CreateIndex
CREATE UNIQUE INDEX "rewarded_ad_entitlements_mediation_session_id_key" ON "rewarded_ad_entitlements"("mediation_session_id");

-- CreateIndex
CREATE UNIQUE INDEX "rewarded_ad_entitlements_provider_provider_reward_id_key" ON "rewarded_ad_entitlements"("provider", "provider_reward_id");

-- CreateIndex
CREATE INDEX "rewarded_ad_entitlements_user_id_created_at_idx" ON "rewarded_ad_entitlements"("user_id", "created_at");

-- AddForeignKey
ALTER TABLE "ad_mediation_sessions" ADD CONSTRAINT "ad_mediation_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ad_provider_attempts" ADD CONSTRAINT "ad_provider_attempts_mediation_session_id_fkey" FOREIGN KEY ("mediation_session_id") REFERENCES "ad_mediation_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rewarded_ad_entitlements" ADD CONSTRAINT "rewarded_ad_entitlements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rewarded_ad_entitlements" ADD CONSTRAINT "rewarded_ad_entitlements_mediation_session_id_fkey" FOREIGN KEY ("mediation_session_id") REFERENCES "ad_mediation_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
