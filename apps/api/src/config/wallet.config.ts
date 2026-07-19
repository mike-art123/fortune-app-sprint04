import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Typed wallet economy configuration. Economy values are never hardcoded in
 * feature code (Sprint 04 rule, honored early) — they live in env with safe
 * defaults and can be tuned without a deploy of new code.
 */
@Injectable()
export class WalletConfig {
  constructor(private readonly config: ConfigService) {}

  /** One-time credit for a brand-new wallet, written as a real ledger row. */
  get starterCoins(): number {
    return this.config.get<number>('WALLET_STARTER_COINS') ?? 30;
  }

  /** Coin price of one reading for users without an active subscription. */
  get readingCostCoins(): number {
    return this.config.get<number>('WALLET_READING_COST') ?? 5;
  }
}
