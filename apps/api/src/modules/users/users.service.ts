import { Injectable } from '@nestjs/common';
import type { User } from '@prisma/client';
import { PrismaService } from '../../infrastructure/database/prisma.service';

/**
 * User lifecycle (Sprint 04 / doc 53). The identity anchor is `tg:<id>` —
 * i.e. the unique telegramId column; one Telegram account maps to exactly one
 * user row, created on first login and updated on later logins.
 */
@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  upsertTelegramUser(input: {
    telegramId: string;
    displayName: string | null;
    languageCode: string | null;
  }): Promise<User> {
    const locale = input.languageCode?.toLowerCase().startsWith('fa') ? 'fa' : undefined;
    return this.prisma.user.upsert({
      where: { telegramId: input.telegramId },
      create: {
        telegramId: input.telegramId,
        displayName: input.displayName,
        ...(locale ? { locale } : {}),
      },
      update: {
        ...(input.displayName !== null ? { displayName: input.displayName } : {}),
        ...(locale ? { locale } : {}),
      },
    });
  }

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }
}
