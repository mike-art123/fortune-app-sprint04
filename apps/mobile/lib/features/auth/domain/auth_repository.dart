import '../../../core/result/result.dart';
import 'auth_session.dart';

/// Successful login: the token to hold and the confirmed identity.
class AuthLogin {
  const AuthLogin({
    required this.accessToken,
    required this.expiresInSeconds,
    required this.session,
  });

  final String accessToken;
  final int expiresInSeconds;
  final AuthSession session;
}

/// Contract the application layer depends on — never the implementation.
abstract interface class AuthRepository {
  /// Exchanges raw Telegram initData for a verified session. The payload is
  /// opaque to the client; only the backend may judge it (doc 51 §32).
  Future<Result<AuthLogin>> loginWithTelegram(String initData);
}
