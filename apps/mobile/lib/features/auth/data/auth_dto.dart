import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Wire-format mapping for the login endpoints (data layer only) —
/// /auth/telegram and /auth/guest share one response shape.
abstract final class AuthDto {
  static AuthLogin fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final expiresIn = json['expiresIn'];
    final user = json['user'];

    if (accessToken is! String ||
        accessToken.isEmpty ||
        expiresIn is! int ||
        user is! Map<String, dynamic>) {
      throw const FormatException('auth payload missing required fields');
    }

    final id = user['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('auth user missing required fields');
    }

    // Telegram logins carry the telegram id; guest (device-anchored) logins
    // return null here. When present it must still be a non-empty string.
    final telegramId = user['telegramId'];
    if (telegramId != null && (telegramId is! String || telegramId.isEmpty)) {
      throw const FormatException('auth user telegramId malformed');
    }

    final displayName = user['displayName'];
    final locale = user['locale'];

    return AuthLogin(
      accessToken: accessToken,
      expiresInSeconds: expiresIn,
      session: AuthSession(
        userId: id,
        telegramId: telegramId is String ? telegramId : null,
        displayName: displayName is String ? displayName : null,
        locale: locale is String ? locale : null,
      ),
    );
  }
}
