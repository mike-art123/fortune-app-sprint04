import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { Injectable } from '@nestjs/common';
import type { Ghazal } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/database/prisma.service';
import { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';

/**
 * The Divan, on demand (docs/hafez-dataset-sourcing.md).
 *
 * The corpus JSON ships inside the deploy (prisma/data travels with the
 * image), and this service settles the open question of how it reaches the
 * production database: lazily, the first time the raw engine is actually
 * asked for a ghazal, with idempotent upserts — no seed step in the deploy,
 * no data bloating the migration history, and a fresh environment heals
 * itself the first time the flag is on.
 *
 * The validation mirrors `prisma/seed.ts` on purpose: the file names its own
 * count, the numbering must cover 1..count with no gaps, and every opening
 * line must equal its first hemistich. A corpus that cannot prove itself is
 * an error, never a partial import — selection draws from 1..count, and a
 * hole in that range would surface as a fal that cannot be fetched.
 */

interface HafezCorpusFile {
  edition: string;
  count: number;
  ghazals: Array<{ number: number; openingLine: string; verses: [string, string][] }>;
}

export interface HafezCorpusInfo {
  edition: string;
  count: number;
}

/** Where the bundled JSON may live, relative to how this process started. */
const CORPUS_CANDIDATES = [
  ['prisma', 'data', 'hafez-ghazals.json'],
  ['apps', 'api', 'prisma', 'data', 'hafez-ghazals.json'],
];

@Injectable()
export class HafezCorpusService {
  private importing: Promise<HafezCorpusInfo> | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly logger: AppLoggerService,
  ) {}

  /**
   * Validates the bundled corpus and makes sure the database holds all of it.
   * Concurrent callers share one in-flight import; a failed import clears the
   * memo so the next reading tries again instead of remembering the outage.
   */
  ensureImported(): Promise<HafezCorpusInfo> {
    this.importing ??= this.importOnce().catch((error: unknown) => {
      this.importing = null;
      throw error;
    });
    return this.importing;
  }

  /** One ghazal by its number in an edition. Missing rows are a loud error. */
  async getGhazal(edition: string, number: number): Promise<Ghazal> {
    const row = await this.prisma.ghazal.findUnique({
      where: { edition_number: { edition, number } },
    });
    if (!row) {
      throw new Error(`ghazal ${number} of edition ${edition} is not in the database`);
    }
    return row;
  }

  private async importOnce(): Promise<HafezCorpusInfo> {
    const corpus = this.loadAndValidate();
    const stored = await this.prisma.ghazal.count({ where: { edition: corpus.edition } });
    if (stored === corpus.count) {
      return { edition: corpus.edition, count: corpus.count };
    }

    for (const ghazal of corpus.ghazals) {
      const data = {
        openingLine: ghazal.openingLine,
        verses: JSON.stringify(ghazal.verses),
      };
      await this.prisma.ghazal.upsert({
        where: { edition_number: { edition: corpus.edition, number: ghazal.number } },
        create: { edition: corpus.edition, number: ghazal.number, ...data },
        update: data,
      });
    }

    const after = await this.prisma.ghazal.count({ where: { edition: corpus.edition } });
    if (after !== corpus.count) {
      throw new Error(`hafez corpus import expected ${corpus.count} rows, found ${after}`);
    }

    this.logger.info('hafez.corpus.imported', {
      edition: corpus.edition,
      count: corpus.count,
      before: stored,
    });
    return { edition: corpus.edition, count: corpus.count };
  }

  private loadAndValidate(): HafezCorpusFile {
    const path = this.resolveCorpusPath();
    const corpus = JSON.parse(readFileSync(path, 'utf8')) as HafezCorpusFile;
    if (!Number.isInteger(corpus.count) || corpus.count <= 0) {
      throw new Error('hafez corpus: the file must claim a positive integer count');
    }
    if (corpus.ghazals.length !== corpus.count) {
      throw new Error(
        `hafez corpus: the file claims ${corpus.count} ghazals but carries ${corpus.ghazals.length}`,
      );
    }
    const numbers = new Set(corpus.ghazals.map((ghazal) => ghazal.number));
    for (let expected = 1; expected <= corpus.count; expected += 1) {
      if (!numbers.has(expected)) {
        throw new Error(`hafez corpus: ghazal ${expected} is missing — numbering must be gapless`);
      }
    }
    for (const ghazal of corpus.ghazals) {
      const opening = ghazal.verses[0];
      if (!opening || ghazal.openingLine !== opening[0]) {
        throw new Error(
          `hafez corpus: ghazal ${ghazal.number} opening line disagrees with its first hemistich`,
        );
      }
    }
    return corpus;
  }

  private resolveCorpusPath(): string {
    for (const candidate of CORPUS_CANDIDATES) {
      const path = join(process.cwd(), ...candidate);
      if (existsSync(path)) return path;
    }
    throw new Error('hafez corpus: prisma/data/hafez-ghazals.json is not on disk');
  }
}
