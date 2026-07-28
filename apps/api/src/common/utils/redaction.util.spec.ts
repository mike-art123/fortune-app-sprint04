import { redact } from './redaction.util';

describe('redaction', () => {
  it('redacts bearer tokens', () => {
    expect(redact('authorization: Bearer abc.def')).not.toContain('abc.def');
  });
  it('redacts telegram initData', () => {
    expect(redact('initData=query_id%3DAAA&user=1')).not.toContain('query_id');
  });
  it('redacts token json fields', () => {
    expect(redact('{"refreshToken":"secret"}')).not.toContain('secret');
  });
  it('redacts the notifications sweep secret header', () => {
    expect(redact('"x-sweep-secret":"abc123def"')).not.toContain('abc123def');
  });
  it('redacts the telegram webhook secret header', () => {
    expect(redact('"x-telegram-bot-api-secret-token":"tok987"')).not.toContain('tok987');
  });
  it('leaves normal text intact', () => {
    expect(redact('hello world')).toBe('hello world');
  });
});
