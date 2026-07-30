import { HttpStatus, Injectable } from '@nestjs/common';
import { BirthMonth, Prisma, type User } from '@prisma/client';
import { DomainException } from '../../common/exceptions/domain.exception';
import { PrismaService } from '../../infrastructure/database/prisma.service';

/** Public profile shape (scope §16) — never leaks internals. */
export interface ProfileView {
  displayName: string | null;
  birthMonth: BirthMonth | null;
  locale: string;
  onboardingCompleted: boolean;
  /** Scope §4: when true, nothing is tailored and nothing is suggested. */
  personalizationOptOut: boolean;
}

/**
 * User lifecycle (Sprint 04 / doc 53). The identity anchor is `tg:<id>` —
 * i.e. the unique telegramId column; one Telegram account maps to exactly one
 * user row, created on first login and updated on later logins. The Play
 * build adds a second anchor: `device:<id>` via the unique deviceId column
 * (guest login) — every user row has exactly one of the two anchors.
 *
 * Profile onboarding (scope §16): the Telegram first name is only a
 * SUGGESTION. Once the user confirms a display name (onboarding complete),
 * later Telegram logins never overwrite it.
 */
@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async upsertTelegramUser(input: {
    telegramId: string;
    displayName: string | null;
    languageCode: string | null;
  }): Promise<User> {
    const locale = input.languageCode?.toLowerCase().startsWith('fa') ? 'fa' : undefined;
    const existing = await this.prisma.user.findUnique({
      where: { telegramId: input.telegramId },
    });
    if (!existing) {
      return this.prisma.user.create({
        data: {
          telegramId: input.telegramId,
          displayName: input.displayName,
          ...(locale ? { locale } : {}),
        },
      });
    }
    // A confirmed name is the user's own choice — Telegram may not overwrite.
    const mayUpdateName = !existing.onboardingCompleted && input.displayName !== null;
    return this.prisma.user.update({
      where: { id: existing.id },
      data: {
        ...(mayUpdateName ? { displayName: input.displayName } : {}),
        ...(locale ? { locale } : {}),
      },
    });
  }

  /**
   * Guest identity for the Play build: the row is created on first login and
   * returned verbatim afterwards. Nothing about the profile is ever derived
   * from the device — the id is an opaque anchor, and a guest's profile works
   * exactly like a Telegram user's.
   */
  async upsertGuestUser(input: { deviceId: string }): Promise<User> {
    const existing = await this.prisma.user.findUnique({
      where: { deviceId: input.deviceId },
    });
    if (existing) return existing;
    try {
      return await this.prisma.user.create({ data: { deviceId: input.deviceId } });
    } catch (error) {
      // Two first-logins can race; the unique index lets exactly one create
      // win, and the loser simply adopts the winner's row.
      const winner = await this.prisma.user.findUnique({
        where: { deviceId: input.deviceId },
      });
      if (winner) return winner;
      throw error;
    }
  }

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async getProfile(userId: string): Promise<ProfileView> {
    const user = await this.requireUser(userId);
    return this.view(user);
  }

  /**
   * First-run onboarding: validate + store name and birth month, then mark
   * onboarding complete. Idempotent: once completed, repeats return the
   * stored profile untouched — a duplicated request can never corrupt data.
   */
  async completeOnboarding(
    userId: string,
    input: { displayName: string; birthMonth: string },
  ): Promise<ProfileView> {
    const user = await this.requireUser(userId);
    if (user.onboardingCompleted) return this.view(user);

    const displayName = this.normalizeDisplayName(input.displayName);
    const birthMonth = this.parseBirthMonth(input.birthMonth);
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        displayName,
        birthMonth,
        onboardingCompleted: true,
        onboardingCompletedAt: new Date(),
        profileVersion: { increment: 1 },
      },
    });
    return this.view(updated);
  }

  /** Profile edit (name, birth month, personalization); bumps the version. */
  async updateProfile(
    userId: string,
    input: {
      displayName?: string;
      birthMonth?: string;
      personalizationOptOut?: boolean;
    },
  ): Promise<ProfileView> {
    await this.requireUser(userId);
    const data: Prisma.UserUpdateInput = { profileVersion: { increment: 1 } };
    if (input.displayName !== undefined) {
      data.displayName = this.normalizeDisplayName(input.displayName);
    }
    if (input.birthMonth !== undefined) {
      data.birthMonth = this.parseBirthMonth(input.birthMonth);
    }
    if (input.personalizationOptOut !== undefined) {
      data.personalizationOptOut = input.personalizationOptOut;
    }
    const updated = await this.prisma.user.update({ where: { id: userId }, data });
    return this.view(updated);
  }

  // ── internals ──────────────────────────────────────────────────────────

  private async requireUser(userId: string): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new DomainException('NOT_FOUND', 'کاربر پیدا نشد.', {
        status: HttpStatus.NOT_FOUND,
      });
    }
    return user;
  }

  /**
   * Display-name hygiene: trim, collapse whitespace runs (ZWNJ preserved),
   * strip control characters and angle brackets (no markup can ever reach a
   * template or prompt), enforce a sane 1..40 length.
   */
  private normalizeDisplayName(raw: string): string {
    const cleaned = Array.from(raw)
      .filter((char) => {
        const code = char.codePointAt(0) ?? 0;
        return code > 0x1f && code !== 0x7f && char !== '<' && char !== '>';
      })
      .join('')
      .replace(/\s+/g, ' ')
      .trim();
    if (cleaned.length === 0 || cleaned.length > 40) {
      throw new DomainException('VALIDATION_FAILED', 'نام واردشده معتبر نیست.', {
        status: HttpStatus.BAD_REQUEST,
      });
    }
    return cleaned;
  }

  private parseBirthMonth(raw: string): BirthMonth {
    const value = raw.trim().toUpperCase();
    if ((Object.values(BirthMonth) as string[]).includes(value)) {
      return value as BirthMonth;
    }
    throw new DomainException('VALIDATION_FAILED', 'ماه تولد معتبر نیست.', {
      status: HttpStatus.BAD_REQUEST,
    });
  }

  private view(user: User): ProfileView {
    return {
      displayName: user.displayName,
      birthMonth: user.birthMonth,
      locale: user.locale,
      onboardingCompleted: user.onboardingCompleted,
      personalizationOptOut: user.personalizationOptOut,
    };
  }
}
