-- Sprint 04 polish: wallets.user_id had no foreign key to users.id, unlike
-- every other identity-anchored table (idempotency_keys, subscriptions).
-- ON DELETE RESTRICT (not CASCADE): a wallet's CoinTransaction ledger must
-- never be silently orphaned or deleted alongside its owner. Deleting a
-- user with a wallet must fail until the wallet (and its ledger) is
-- explicitly handled by the caller.

-- AddForeignKey
ALTER TABLE "wallets" ADD CONSTRAINT "wallets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
