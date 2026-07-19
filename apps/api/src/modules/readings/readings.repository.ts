import { Injectable } from '@nestjs/common';
import type { Reading } from '@prisma/client';
import { PrismaService } from '../../infrastructure/database/prisma.service';

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
}
