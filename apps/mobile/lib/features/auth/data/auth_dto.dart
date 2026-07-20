import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Wire-format mapping for POST /auth/telegram (data layer only).
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
    final telegramId = user['telegramId'];
    if (id is! String ||
        id.isEmpty ||
        telegramId is! String ||
        telegramId.isEmpty) {
      throw const FormatException('auth user missing required fields');
    }

    final displayName = user['displayName'];
    final locale = user['locale'];

    return AuthLogin(
      accessToken: accessToken,
      expiresInSeconds: expiresIn,
      session: AuthSession(
        userId: id,
        telegramId: telegramId,
        displayName: displayName is String ? displayName : null,
        locale: locale is String ? locale : null,
      ),
    );
  }
}
