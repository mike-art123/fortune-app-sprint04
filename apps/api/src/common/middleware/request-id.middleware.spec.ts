import { RequestIdMiddleware } from './request-id.middleware';

function run(incoming?: string): { forwarded: string; echoed: string } {
  const mw = new RequestIdMiddleware();
  const req: Record<string, unknown> = { headers: incoming ? { 'x-request-id': incoming } : {} };
  let echoed = '';
  const res = { setHeader: (_: string, v: string) => (echoed = v) };
  mw.use(req as never, res as never, () => undefined);
  return { forwarded: (req as { requestId: string }).requestId, echoed };
}

describe('request id middleware', () => {
  it('accepts a well-formed incoming id', () => {
    const { forwarded } = run('abc-123-def-456');
    expect(forwarded).toBe('abc-123-def-456');
  });
  it('replaces hostile ids', () => {
    const { forwarded } = run('<script>alert(1)</script>');
    expect(forwarded).not.toContain('<');
    expect(forwarded).toMatch(/^[0-9a-f-]{36}$/);
  });
  it('echoes the id back in the response header', () => {
    const { forwarded, echoed } = run();
    expect(echoed).toBe(forwarded);
  });
});
