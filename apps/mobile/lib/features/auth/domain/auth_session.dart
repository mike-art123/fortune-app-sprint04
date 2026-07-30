/// The authenticated identity as the backend confirmed it (Sprint 04/doc 53).
/// The client never invents identity — this exists only after the backend
/// verified Telegram initData or a guest device id (or a stored, unexpired
/// access token). Guest sessions simply have no [telegramId].
class AuthSession {
  const AuthSession({
    required this.userId,
    this.telegramId,
    this.displayName,
    this.locale,
  });

  final String userId;
  final String? telegramId;
  final String? displayName;
  final String? locale;
}
