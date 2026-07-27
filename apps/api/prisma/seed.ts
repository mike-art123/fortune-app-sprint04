import { PrismaClient } from '@prisma/client';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * Idempotent development seed (doc 52 §42). No fake users, balances, or
 * entitlements — only infrastructure defaults, clearly non-production.
 */
const prisma = new PrismaClient();

/**
 * Hafez corpus import (docs/hafez-dataset-sourcing.md).
 *
 * `prisma/data/hafez-ghazals.json` is produced by the extraction step from the
 * Ganjoor dump and committed with the repo; until it exists this import skips
 * with one line and seeds nothing. When it runs it refuses to half-import: the
 * file names its own count, and the seed fails loudly unless exactly that many
 * ghazals are present, numbered 1..count with no gaps — selection will later
 * draw from that whole range, and a hole in it would be a fal that cannot be
 * fetched. Rows upsert on (edition, number), so re-running refreshes text in
 * place and can never duplicate a ghazal.
 */
interface HafezCorpusFile {
  edition: string;
  count: number;
  ghazals: Array<{ number: number; openingLine: string; verses: [string, string][] }>;
}

const HAFEZ_CORPUS_PATH = join(__dirname, 'data', 'hafez-ghazals.json');

async function seedHafezGhazals(): Promise<void> {
  if (!existsSync(HAFEZ_CORPUS_PATH)) {
    console.log('hafez corpus: prisma/data/hafez-ghazals.json not present — skipping import');
    return;
  }
  const corpus = JSON.parse(readFileSync(HAFEZ_CORPUS_PATH, 'utf8')) as HafezCorpusFile;
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
  for (const ghazal of corpus.ghazals) {
    await prisma.ghazal.upsert({
      where: { edition_number: { edition: corpus.edition, number: ghazal.number } },
      create: {
        edition: corpus.edition,
        number: ghazal.number,
        openingLine: ghazal.openingLine,
        verses: JSON.stringify(ghazal.verses),
      },
      update: { openingLine: ghazal.openingLine, verses: JSON.stringify(ghazal.verses) },
    });
  }
  const stored = await prisma.ghazal.count({ where: { edition: corpus.edition } });
  if (stored !== corpus.count) {
    throw new Error(`hafez corpus: expected ${corpus.count} stored ghazals, found ${stored}`);
  }
  console.log(`hafez corpus: ${stored} ghazals present for edition ${corpus.edition}`);
}

async function main(): Promise<void> {
  await prisma.systemSetting.upsert({
    where: { key: 'seed.environment' },
    create: { key: 'seed.environment', value: 'development' },
    update: { value: 'development' },
  });

  await prisma.featureFlag.upsert({
    where: { key: 'system.maintenance-banner' },
    create: { key: 'system.maintenance-banner', enabled: false, note: 'dev default' },
    update: {},
  });

  await seedHafezGhazals();
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
