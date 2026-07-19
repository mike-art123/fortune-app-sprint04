/// Typed, user-safe failure model (doc 51 §23).
/// Infrastructure exceptions are mapped here — raw errors never reach the UI.
enum FailureKind {
  networkUnavailable,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  rateLimited,
  /// Not enough coins for a paid reading (Sprint 04 economy).
  insufficientCoins,
  /// The surface requires an active subscription (Sprint 04 economy).
  subscriptionRequired,
  server,
  parsing,
  storage,
  unknown,
}

class AppFailure {
  const AppFailure({
    required this.kind,
    required this.messageKey,
    this.developerMessage,
    this.requestId,
  });

  final FailureKind kind;

  /// Localization key resolved by [FailureMessageResolver]. Never a raw
  /// backend string — the backend message is untrusted product copy.
  final String messageKey;

  /// Developer-facing detail. Logged, never displayed.
  final String? developerMessage;

  final String? requestId;

  /// Whether the user can meaningfully retry the same action.
  bool get isRetryable => switch (kind) {
        FailureKind.networkUnavailable ||
        FailureKind.timeout ||
        FailureKind.server ||
        FailureKind.rateLimited =>
          true,
        _ => false,
      };

  /// Whether the session must be re-established.
  bool get requiresReauth =>
      kind == FailureKind.unauthorized || kind == FailureKind.forbidden;

  @override
  String toString() => 'AppFailure(${kind.name}, $messageKey, req=$requestId)';
}
