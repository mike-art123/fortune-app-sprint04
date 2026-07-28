import { Injectable } from '@nestjs/common';
import type { Reading } from '@prisma/client';
import { PrismaService } from '../../infrastructure/database/prisma.service';

/**
 * A reading reduced to what anything outside this module may see: which
 * fortune, and when. The words themselves stay in this table — the history
 * summary (scope §6) is built from the shape of someone's visits, never from
 * what they were told.
 */
export interface ReadingMoment {
  id: string;
  fortuneId: string;
  createdAt: Date;
}

export interface CreateReadingRecord {
  userId: string;
  fortuneId: string;
  title: string;
  content: string;
  inputJson: string;
  requestId: string | null;
}

/** Persistence boundary — controllers never touch Prisma (doc 52 §47). */
@Injectable()
export class ReadingsRepository {
  constructor(private readonly prisma: PrismaService) {}

  create(record: CreateReadingRecord): Promise<Reading> {
    return this.prisma.reading.create({ data: record });
  }

  findById(id: string): Promise<Reading | null> {
    return this.prisma.reading.findUnique({ where: { id } });
  }

  /** Erase every reading the caller owns. Returns how many rows went. */
  async deleteAllForUser(userId: string): Promise<number> {
    const { count } = await this.prisma.reading.deleteMany({ where: { userId } });
    return count;
  }

  /**
   * Delete one reading, but only if this user owns it. Scoping the delete by
   * userId (rather than a separate ownership read) means another user's id
   * simply matches nothing and removes nothing — count 0, and no way to learn
   * whether that id exists for someone else.
   */
  async deleteOwned(id: string, userId: string): Promise<number> {
    const { count } = await this.prisma.reading.deleteMany({ where: { id, userId } });
    return count;
  }

  /**
   * Everything this reader saw since an instant, reduced to what a summary is
   * allowed to know (scope §6): which fortune, and when. The text column is
   * deliberately not selected — it never leaves this table for that feature.
   */
  listSince(params: { userId: string; since: Date }): Promise<ReadingMoment[]> {
    const { userId, since } = params;
    return this.prisma.reading.findMany({
      where: { userId, createdAt: { gte: since } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      select: { id: true, fortuneId: true, createdAt: true },
    });
  }

  /**
   * Newest-first page. `cursorId` is the id of the last item of the previous
   * page (already decoded). We fetch one extra row to learn whether another
   * page exists without a second query. Ordering ties on `id` so rows created
   * in the same millisecond still paginate deterministically.
   *
   * Sprint 04: always scoped to the owning user.
   */
  list(params: { userId: string; limit: number; cursorId?: string }): Promise<Reading[]> {
    const { userId, limit, cursorId } = params;
    return this.prisma.reading.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    });
  }

  /** Mark or clear one reading as saved — only if this user owns it. */
  async setSaved(id: string, userId: string, saved: boolean): Promise<number> {
    const { count } = await this.prisma.reading.updateMany({
      where: { id, userId },
      data: { savedAt: saved ? new Date() : null },
    });
    return count;
  }

  /** Newest-saved-first page of the caller's saved readings. */
  listSaved(params: { userId: string; limit: number; cursorId?: string }): Promise<Reading[]> {
    const { userId, limit, cursorId } = params;
    return this.prisma.reading.findMany({
      where: { userId, savedAt: { not: null } },
      orderBy: [{ savedAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    });
  }

  /** The caller's most recent readings (capped), for deriving intentions. */
  recentForUser(userId: string, take: number): Promise<Reading[]> {
    return this.prisma.reading.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take,
    });
  }
}
