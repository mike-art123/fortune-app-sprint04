import { Module } from '@nestjs/common';
import { WalletController } from './wallet.controller';
import { WalletRepository } from './wallet.repository';
import { WalletService } from './wallet.service';

/** Wallet (Sprint 04 / doc 53): ledger-backed coin balance, debit + refund. */
@Module({
  controllers: [WalletController],
  providers: [WalletService, WalletRepository],
  exports: [WalletService],
})
export class WalletModule {}
