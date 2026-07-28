import { ReadingsService } from './readings.service';

const principal = { userId: 'u1', telegramId: '42', roles: ['user'] as const };

const repository = {
  deleteAllForUser: jest.fn(),
  deleteOwned: jest.fn(),
};

const logger = { debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() };

// Only the repository and logger take part in deletion; the rest of the
// service's collaborators are never touched on these paths.
const service = new ReadingsService(
  repository as never,
  {} as never,
  {} as never,
  {} as never,
  {} as never,
  {} as never,
  {} as never,
  logger as never,
);

beforeEach(() => jest.clearAllMocks());

describe('ReadingsService.clearHistory', () => {
  it('wipes only the caller and reports how many went', async () => {
    repository.deleteAllForUser.mockResolvedValue(3);

    const res = await service.clearHistory(principal as never);

    expect(repository.deleteAllForUser).toHaveBeenCalledWith('u1');
    expect(res).toEqual({ deleted: 3 });
    expect(logger.info).toHaveBeenCalledWith(
      'reading.history.cleared',
      expect.objectContaining({ userId: 'u1', deleted: 3 }),
    );
  });

  it('clearing an empty history is zero, never an error', async () => {
    repository.deleteAllForUser.mockResolvedValue(0);

    const res = await service.clearHistory(principal as never);

    expect(res).toEqual({ deleted: 0 });
  });
});

describe('ReadingsService.deleteReading', () => {
  it('removes one reading the caller owns and reports it', async () => {
    repository.deleteOwned.mockResolvedValue(1);

    const res = await service.deleteReading('c9', principal as never);

    expect(repository.deleteOwned).toHaveBeenCalledWith('c9', 'u1');
    expect(res).toEqual({ deleted: 1 });
  });

  it("an unknown or someone else's id is a quiet no-op, not an error", async () => {
    repository.deleteOwned.mockResolvedValue(0);

    const res = await service.deleteReading('stranger', principal as never);

    expect(res).toEqual({ deleted: 0 });
  });
});
