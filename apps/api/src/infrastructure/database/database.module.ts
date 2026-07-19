import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { PrismaHealthIndicator } from './prisma-health.indicator';
import { TransactionService } from './transaction.service';

@Global()
@Module({
  providers: [PrismaService, PrismaHealthIndicator, TransactionService],
  exports: [PrismaService, PrismaHealthIndicator, TransactionService],
})
export class DatabaseModule {}
