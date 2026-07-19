import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/auth_repository_impl.dart';
import '../domain/access_token_claims.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Explicit session lifecycle (Sprint 04 / doc 53). No boolean soup.
sealed class AuthState {
  const AuthState();
}

/// Before [AuthController.bootstrap] has run.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class AuthInProgress extends AuthState {
  const AuthInProgress();
}

final class Authenticated extends AuthState {
  const Authenticated(this.session);
  final AuthSession session;
}

enum UnauthenticatedReason {
  /// Running outside Telegram with no development seam configured.
  outsideTelegram,

  /// The backend refused the login (bad/stale initData or rejected token).
  rejected,

  /// Could not reach the backend; retry is meaningful.
  network,
}

final class Unauthenticated extends AuthState {
  const Unauthenticated(this.reason);
  final UnauthenticatedReason reason;
}

/// Owns the session: bootstraps it at startup, re-establishes it after a 401,
/// and never fabricates identity — every session comes from the backend.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final events = ref.watch(sessionEventsProvider);
    final subscription = events.onUnauthorized.listen((_) => _onUnauthorized());
    ref.onDispose(subscription.cancel);
    return const AuthUnknown();
  }

  /// Called once during startup (and by retry). A stored, unexpired token is
  /// reused as-is; otherwise a fresh Telegram login is attempted. Failure is a
  /// valid, calm end state — startup never crashes on auth.
  Future<void> bootstrap() async {
    if (state is AuthInProgress) return;
    state = const AuthInProgress();

    final tokens = ref.read(tokenStoreProvider);
    final stored = await tokens.readAccessToken();
    if (stored != null && stored.isNotEmpty) {
      final claims = AccessTokenClaims.decode(stored);
      if (claims != null && claims.isFresh) {
        state = Authenticated(
          AuthSession(userId: claims.userId, telegramId: claims.telegramId),
        );
        return;
      }
      await tokens.clear();
    }

    await _loginViaTelegram();
  }

  Future<void> retry() async {
    if (state is AuthInProgress) return;
    state = const AuthInProgress();
    await _loginViaTelegram();
  }

  /// Drops the session locally. (No backend session state exists to revoke —
  /// tokens simply expire.)
  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const Unauthenticated(UnauthenticatedReason.outsideTelegram);
  }

  Future<void> _loginViaTelegram() async {
    final initData = _initData();
    if (initData == null) {
      state = const Unauthenticated(UnauthenticatedReason.outsideTelegram);
      return;
    }

    final result = await ref.read(authRepositoryProvider).loginWithTelegram(initData);
    state = await result.fold(
      onSuccess: (login) async {
        await ref.read(tokenStoreProvider).saveAccessToken(login.accessToken);
        return Authenticated(login.session);
      },
      onFailure: (failure) async => Unauthenticated(_reasonFor(failure)),
    );
  }

  /// The backend refused our bearer token mid-session: drop it and attempt one
  /// fresh Telegram login (initData may still be valid inside the Mini App).
  Future<void> _onUnauthorized() async {
    if (state is AuthInProgress) return;
    await ref.read(tokenStoreProvider).clear();
    state = const AuthInProgress();
    await _loginViaTelegram();
  }

  /// Raw initData: the Telegram bridge in production; inside development the
  /// `DEV_TELEGRAM_INITDATA` dart-define is an explicit test seam (it still
  /// goes through full backend verification — nothing is bypassed).
  String? _initData() {
    final bridge = ref.read(telegramBridgeProvider);
    final fromBridge = bridge.isAvailable ? bridge.initData : null;
    if (fromBridge != null && fromBridge.isNotEmpty) return fromBridge;

    final config = ref.read(appConfigProvider);
    final seam = config.devTelegramInitData;
    if (seam != null && seam.isNotEmpty) return seam;

    return null;
  }

  UnauthenticatedReason _reasonFor(AppFailure failure) => switch (failure.kind) {
        FailureKind.networkUnavailable ||
        FailureKind.timeout ||
        FailureKind.server ||
        FailureKind.rateLimited =>
          UnauthenticatedReason.network,
        _ => UnauthenticatedReason.rejected,
      };
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(apiClientProvider));
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
