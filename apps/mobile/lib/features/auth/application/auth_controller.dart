import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/guest_auth_switch.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/result/result.dart';
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
  /// reused as-is; otherwise a fresh login is attempted — Telegram inside the
  /// Mini App, guest on the Play build. Failure is a valid, calm end state —
  /// startup never crashes on auth.
  Future<void> bootstrap() async {
    if (state is AuthInProgress) return;
    state = const AuthInProgress();

    final stored = await _readStoredTokenSafely();
    if (stored != null && stored.isNotEmpty) {
      final claims = AccessTokenClaims.decode(stored);
      if (claims != null && claims.isFresh) {
        state = Authenticated(
          AuthSession(userId: claims.userId, telegramId: claims.telegramId),
        );
        return;
      }
      await _runGuarded(() => ref.read(tokenStoreProvider).clear());
    }

    await _establishSession();
  }

  Future<void> retry() async {
    if (state is AuthInProgress) return;
    state = const AuthInProgress();
    await _establishSession();
  }

  /// Drops the session locally. (No backend session state exists to revoke —
  /// tokens simply expire.)
  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const Unauthenticated(UnauthenticatedReason.outsideTelegram);
  }

  /// Telegram when initData exists (inside the Mini App or via the dev seam);
  /// otherwise the guest path on builds that enable it; otherwise a calm
  /// Unauthenticated end state.
  Future<void> _establishSession() async {
    final initData = _initData();
    if (initData != null) {
      await _loginWithTelegram(initData);
      return;
    }
    if (ref.read(guestAuthEnabledProvider)) {
      await _loginAsGuest();
      return;
    }
    state = const Unauthenticated(UnauthenticatedReason.outsideTelegram);
  }

  Future<void> _loginWithTelegram(String initData) async {
    final result =
        await ref.read(authRepositoryProvider).loginWithTelegram(initData);
    await _applyLoginResult(result);
  }

  /// Guest login (Play build): the install's stable device id is the whole
  /// identity. The id is app-generated and never logged.
  Future<void> _loginAsGuest() async {
    final deviceId = await _guestDeviceId();
    final result =
        await ref.read(authRepositoryProvider).loginAsGuest(deviceId);
    await _applyLoginResult(result);
  }

  Future<void> _applyLoginResult(Result<AuthLogin> result) async {
    state = await result.fold(
      onSuccess: (login) async {
        final store = ref.read(tokenStoreProvider);
        await _runGuarded(() => store.saveAccessToken(login.accessToken));
        return Authenticated(login.session);
      },
      onFailure: (failure) async => Unauthenticated(_reasonFor(failure)),
    );
  }

  /// The install's stable device id: minted once (UUID v4), then reused. A
  /// failed preference write is tolerated — the next launch would mint a
  /// fresh guest, a degraded but valid outcome.
  Future<String> _guestDeviceId() async {
    final storage = ref.read(localStorageProvider);
    final existing = storage.getString(PrefKeys.guestDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = const Uuid().v4();
    await _runGuarded(() => storage.setString(PrefKeys.guestDeviceId, fresh));
    return fresh;
  }

  /// The backend refused our bearer token mid-session: drop it and attempt
  /// one fresh login (initData may still be valid inside the Mini App; the
  /// guest anchor never goes stale).
  Future<void> _onUnauthorized() async {
    if (state is AuthInProgress) return;
    await ref.read(tokenStoreProvider).clear();
    state = const AuthInProgress();
    await _establishSession();
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

  /// Secure storage can hang or reject on some web engines (e.g. the Telegram
  /// in-app browser). A stored token is only an optimisation, so a slow or
  /// failed read is treated as "no session" and we fall through to a fresh
  /// Telegram login. Without this bound the whole app can hang on the splash
  /// before any API request is ever made.
  Future<String?> _readStoredTokenSafely() async {
    try {
      return await ref
          .read(tokenStoreProvider)
          .readAccessToken()
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      return null;
    }
  }

  /// Best-effort secure-storage write/clear that can never block the session
  /// flow: a hang or failure is bounded and swallowed (persistence is a
  /// convenience, never a gate).
  Future<void> _runGuarded(Future<void> Function() op) async {
    try {
      await op().timeout(const Duration(seconds: 4));
    } catch (_) {
      // Intentionally ignored — see doc above.
    }
  }

  UnauthenticatedReason _reasonFor(AppFailure failure) =>
      switch (failure.kind) {
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

/// Whether this build may establish a guest (device-anchored) session.
/// Real builds inherit the compile-time switch; tests override the provider.
final guestAuthEnabledProvider = Provider<bool>((ref) => kGuestAuthEnabled);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
