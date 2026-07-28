import { ReadingsService } from './readings.service';

const principal = { userId: 'u1', telegramId: '42', roles: ['user'] as const };

const repository = {
  setSaved: jest.fn(),
  listSaved: jest.fn(),
  recentForUser: jest.fn(),
};

// Saving, listing saved, and deriving intentions touch only the repository;
// every other collaborator stays untouched on these paths.
const service = new ReadingsService(
  repository as never,
  {} as never,
  {} as never,
  {} as never,
  {} as never,
  {} as never,
  {} as never,
  {} as never,
  {} as never,
);

beforeEach(() => jest.clearAllMocks());

function row(id: string, intention: unknown, createdAt = '2026-01-01T00:00:00Z') {
  return {
    id,
    userId: 'u1',
    fortuneId: 'hafez',
    title: 'عنوان',
    content: 'متن',
    inputJson: JSON.stringify({ intention }),
    requestId: null,
    createdAt: new Date(createdAt),
    savedAt: null,
  };
}

describe('ReadingsService.setSaved', () => {
  it('saving one the caller owns reports saved:true', async () => {
    repository.setSaved.mockResolvedValue(1);

    const res = await service.setSaved('c1', true, principal as never);

    expect(repository.setSaved).toHaveBeenCalledWith('c1', 'u1', true);
    expect(res).toEqual({ saved: true });
  });

  it("an unknown or someone else's id reports saved:false", async () => {
    repository.setSaved.mockResolvedValue(0);

    const res = await service.setSaved('stranger', true, principal as never);

    expect(res).toEqual({ saved: false });
  });

  it('unsaving always reports saved:false', async () => {
    repository.setSaved.mockResolvedValue(1);

    const res = await service.setSaved('c1', false, principal as never);

    expect(repository.setSaved).toHaveBeenCalledWith('c1', 'u1', false);
    expect(res).toEqual({ saved: false });
  });
});

describe('ReadingsService.listSaved', () => {
  it('returns a saved page newest-first with a cursor when full', async () => {
    repository.listSaved.mockResolvedValue([row('c3', ''), row('c2', ''), row('c1', '')]);

    const page = await service.listSaved({ limit: 2 }, principal as never);

    expect(page.items.map((i) => i.id)).toEqual(['c3', 'c2']);
    expect(page.nextCursor).not.toBeNull();
  });

  it('a short page has no next cursor', async () => {
    repository.listSaved.mockResolvedValue([row('c1', '')]);

    const page = await service.listSaved({ limit: 20 }, principal as never);

    expect(page.items.map((i) => i.id)).toEqual(['c1']);
    expect(page.nextCursor).toBeNull();
  });
});

describe('ReadingsService.listIntentions', () => {
  it('keeps only readings that carry a non-empty intention', async () => {
    repository.recentForUser.mockResolvedValue([
      row('c3', 'دلم آرام بگیرد'),
      row('c2', '   '),
      row('c1', undefined),
    ]);

    const out = await service.listIntentions(principal as never);

    expect(out.map((i) => i.id)).toEqual(['c3']);
    expect(out[0]).toMatchObject({ fortune: 'hafez', intention: 'دلم آرام بگیرد' });
  });

  it('bad input JSON is skipped, never thrown', async () => {
    repository.recentForUser.mockResolvedValue([
      { id: 'x', fortuneId: 'hafez', inputJson: 'not json', createdAt: new Date() },
    ]);

    const out = await service.listIntentions(principal as never);

    expect(out).toEqual([]);
  });
});
