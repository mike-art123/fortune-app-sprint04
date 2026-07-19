import 'dart:convert';

/// Client-side *peek* into our own access token.
///
/// SECURITY NOTE (doc 51 §33): the client is untrusted and CANNOT verify the
/// signature — nor does it try. Decoding here serves exactly two UX purposes:
/// knowing who the session belongs to, and skipping a doomed request when the
/// token is already expired. The backend remains the only verifier.
class AccessTokenClaims {
  const AccessTokenClaims({
    required this.userId,
    required this.telegramId,
    required this.expiresAt,
  });

  final String userId;
  final String telegramId;
  final DateTime expiresAt;

  /// Fresh enough to be worth sending (small margin so we never race expiry).
  bool get isFresh =>
      expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 1)));

  /// Returns null for anything that is not a well-formed JWT of ours.
  static AccessTokenClaims? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return null;
      final sub = payload['sub'];
      final tid = payload['tid'];
      final exp = payload['exp'];
      if (sub is! String || sub.isEmpty) return null;
      if (tid is! String || tid.isEmpty) return null;
      if (exp is! int || exp <= 0) return null;
      return AccessTokenClaims(
        userId: sub,
        telegramId: tid,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000),
      );
    } catch (_) {
      return null;
    }
  }
}
