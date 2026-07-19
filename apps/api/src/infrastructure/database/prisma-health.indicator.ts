import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Injectable()
export class PrismaHealthIndicator {
  constructor(private readonly prisma: PrismaService) {}

  async isHealthy(): Promise<boolean> {
    try {
      return await this.prisma.ping();
    } catch {
      return false;
    }
  }
}
