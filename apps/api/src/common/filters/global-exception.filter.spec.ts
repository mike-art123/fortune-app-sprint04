import { HttpStatus } from '@nestjs/common';
import { DomainException } from '../exceptions/domain.exception';
import { GlobalExceptionFilter } from './global-exception.filter';
import type { ApiErrorBody } from '../types/api-error';

const logger = { error: jest.fn(), info: jest.fn(), warn: jest.fn(), debug: jest.fn() };

function invoke(exception: unknown): { status: number; body: ApiErrorBody } {
  const filter = new GlobalExceptionFilter(logger as never);
  let captured: { status: number; body: ApiErrorBody } = { status: 0, body: {} as ApiErrorBody };
  const res = {
    status(code: number) {
      captured.status = code;
      return { json: (b: ApiErrorBody) => (captured.body = b) };
    },
  };
  const host = {
    switchToHttp: () => ({
      getResponse: () => res,
      getRequest: () => ({ ctx: { requestId: 'req-1' }, url: '/x' }),
    }),
  };
  filter.catch(exception, host as never);
  return captured;
}

describe('global exception filter', () => {
  it('normalizes domain exceptions with their code', () => {
    const { status, body } = invoke(
      new DomainException('INSUFFICIENT_COINS', 'موجودی کافی نیست.', {
        status: HttpStatus.UNPROCESSABLE_ENTITY,
      }),
    );
    expect(status).toBe(422);
    expect(body.error.code).toBe('INSUFFICIENT_COINS');
    expect(body.requestId).toBe('req-1');
  });

  it('turns unknown errors into a safe INTERNAL error', () => {
    const { status, body } = invoke(new Error('SELECT * FROM secrets'));
    expect(status).toBe(500);
    expect(body.error.code).toBe('INTERNAL');
    expect(JSON.stringify(body)).not.toContain('SELECT');
  });
});
