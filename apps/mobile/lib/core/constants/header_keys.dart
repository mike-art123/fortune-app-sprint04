/// HTTP header names shared with the backend contract (doc 33).
abstract final class HeaderKeys {
  static const requestId = 'X-Request-Id';
  static const clientVersion = 'X-Client-Version';
  static const platform = 'X-Platform';
  static const acceptLanguage = 'Accept-Language';
  static const authorization = 'Authorization';
  static const idempotencyKey = 'Idempotency-Key';
}
