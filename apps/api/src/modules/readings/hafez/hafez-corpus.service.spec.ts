import { HafezCorpusService } from './hafez-corpus.service';
import type { PrismaService } from '../../../infrastructure/database/prisma.service';
import type { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';

/**
 * These tests run against the real committed corpus at
 * prisma/data/hafez-ghazals.json — the validation is only worth having if it
 * passes on the file we actually ship.
 */

type GhazalDelegate = {
  count: jest.Mock;
  upsert: jest.Mock;
  findUnique: jest.Mock;
};

function makePrisma(): PrismaService & { ghazal: GhazalDelegate } {
  return {
    ghazal: {
      count: jest.fn(),
      upsert: jest.fn().mockResolvedValue({}),
      findUnique: jest.fn(),
    },
  } as unknown as PrismaService & { ghazal: GhazalDelegate };
}

function makeLogger(): AppLoggerService {
  return {
    debug: () => undefined,
    info: () => undefined,
    warn: () => undefined,
    error: () => undefined,
  } as unknown as AppLoggerService;
}

describe('HafezCorpusService', () => {
  it('accepts the committed corpus and skips importing when all rows exist', async () => {
    const prisma = makePrisma();
    prisma.ghazal.count.mockResolvedValue(495);
    const service = new HafezCorpusService(prisma, makeLogger());

    const info = await service.ensureImported();

    expect(info).toEqual({ edition: 'ganjoor-db-2017', count: 495 });
    expect(prisma.ghazal.upsert).not.toHaveBeenCalled();
  });

  it('imports every ghazal when the table is empty', async () => {
    const prisma = makePrisma();
    prisma.ghazal.count.mockResolvedValueOnce(0).mockResolvedValueOnce(495);
    const service = new HafezCorpusService(prisma, makeLogger());

    const info = await service.ensureImported();

    expect(info.count).toBe(495);
    expect(prisma.ghazal.upsert).toHaveBeenCalledTimes(495);
  });

  it('refuses a half-finished import', async () => {
    const prisma = makePrisma();
    prisma.ghazal.count.mockResolvedValueOnce(0).mockResolvedValueOnce(200);
    const service = new HafezCorpusService(prisma, makeLogger());

    await expect(service.ensureImported()).rejects.toThrow('expected 495 rows');
  });

  it('shares one import across concurrent callers', async () => {
    const prisma = makePrisma();
    prisma.ghazal.count.mockResolvedValue(495);
    const service = new HafezCorpusService(prisma, makeLogger());

    await Promise.all([service.ensureImported(), service.ensureImported()]);
    await service.ensureImported();

    expect(prisma.ghazal.count).toHaveBeenCalledTimes(1);
  });

  it('forgets a failed import so the next reading can try again', async () => {
    const prisma = makePrisma();
    prisma.ghazal.count.mockRejectedValueOnce(new Error('db down')).mockResolvedValue(495);
    const service = new HafezCorpusService(prisma, makeLogger());

    await expect(service.ensureImported()).rejects.toThrow('db down');
    await expect(service.ensureImported()).resolves.toEqual({
      edition: 'ganjoor-db-2017',
      count: 495,
    });
  });

  it('fetches a ghazal by its number within an edition', async () => {
    const prisma = makePrisma();
    const row = { id: 'g255', edition: 'ganjoor-db-2017', number: 255 };
    prisma.ghazal.findUnique.mockResolvedValue(row);
    const service = new HafezCorpusService(prisma, makeLogger());

    await expect(service.getGhazal('ganjoor-db-2017', 255)).resolves.toBe(row);
    expect(prisma.ghazal.findUnique).toHaveBeenCalledWith({
      where: { edition_number: { edition: 'ganjoor-db-2017', number: 255 } },
    });
  });

  it('treats a missing ghazal as a loud error, never a silent fallback', async () => {
    const prisma = makePrisma();
    prisma.ghazal.findUnique.mockResolvedValue(null);
    const service = new HafezCorpusService(prisma, makeLogger());

    await expect(service.getGhazal('ganjoor-db-2017', 9999)).rejects.toThrow('9999');
  });
});
