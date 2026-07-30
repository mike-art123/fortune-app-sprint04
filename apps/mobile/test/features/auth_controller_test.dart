import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/config/app_config.dart';
import 'package:fortune_app/core/config/app_flavor.dart';
import 'package:fortune_app/core/config/feature_flags.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/persistence/local_storage.dart';
import 'package:fortune_app/core/persistence/secure_storage.dart';
import 'package:fortune_app/core/platform/telegram_platform_bridge.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/auth/application/auth_controller.dart';
import 'package:fortune_app/features/auth/domain/access_token_claims.dart';
import 'package:fortune_app/features/auth/domain/auth_repository.dart';
import 'package:fortune_app/features/auth/domain/auth_session.dart';
import 'package:fortune_app/shared/providers/shared_providers.dart';

/// Builds an unsigned-but-well-formed JWT for claim decoding. The client
/// never verifies signatures (the backend does), so 'sig' is enough here.
/// Guest tokens simply omit `tid`.
String fakeJwt({required String sub, required int exp, String? tid}) {
  String b64(Map<String, Object> m) =>
      base64Url.encode(utf8.encode(json.encode(m))).replaceAll('=', '');
  final header = b64({'alg': 'EdDSA', 'typ': 'JWT'});
  final payload = b64({'sub': sub, if (tid != null) 'tid': tid, 'exp': exp});
  return '$header.$payload.sig';
}

int inOneHour() =>
    DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> map = {};
  @override
  Future<String?> read(String key) async => map[key];
  @override
  Future<void> write(String key, String value) async => map[key] = value;
  @override
  Future<void> delete(String key) async => map.remove(key);
  @override
  Future<void> clear() async => map.clear();
}

class _FakeBridge implements TelegramPlatformBridge {
  _FakeBridge(this._initData);
  final String? _initData;
  @override
  bool get isAvailable => _initData != null;
  @override
  String? get initData => _initData;
  @override
  Future<void> expandViewport() async {}
  @override
  Future<void> hapticImpact() async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> openLink(String url) async {}
  @override
  Future<void> openTelegramLink(String url) async {}
  @override
  Future<void> showBackButton() async {}
  @override
  Future<void> hideBackButton() async {}
  @override
  void setBackButtonHandler(void Function()? handler) {}
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.result);
  Result<AuthLogin> result;
  int calls = 0;
  int guestCalls = 0;
  String? lastInitData;
  String? lastDeviceId;

  @override
  Future<Result<AuthLogin>> loginWithTelegram(String initData) async {
    calls++;
    lastInitData = initData;
    return result;
  }

  @override
  Future<Result<AuthLogin>> loginAsGuest(String deviceId) async {
    guestCalls++;
    lastDeviceId = deviceId;
    return result;
  }
}

AuthLogin _login({String userId = 'u1'}) => AuthLogin(
      accessToken: fakeJwt(sub: userId, tid: '42', exp: inOneHour()),
      expiresInSeconds: 3600,
      session:
          AuthSession(userId: userId, telegramId: '42', displayName: 'سارا'),
    );

AuthLogin _guestLogin({String userId = 'g1'}) => AuthLogin(
      accessToken: fakeJwt(sub: userId, exp: inOneHour()),
      expiresInSeconds: 3600,
      session: AuthSession(userId: userId),
    );

AppConfig _config({String? devInitData}) => AppConfig(
      flavor: AppFlavor.development,
      apiBaseUrl: 'http://localhost:3000/api/v1',
      connectTimeout: const Duration(seconds: 1),
      receiveTimeout: const Duration(seconds: 1),
      devTelegramInitData: devInitData,
      flags: const FeatureFlags(
        analyticsEnabled: false,
        crashReportingEnabled: false,
        debugMenuEnabled: false,
      ),
    );

void main() {
  ProviderContainer make({
    required AuthRepository repo,
    required TelegramPlatformBridge bridge,
    required SecureStorage storage,
    String? devInitData,
    LocalStorage? localStorage,
    bool guestAuthEnabled = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        telegramBridgeProvider.overrideWithValue(bridge),
        secureStorageProvider.overrideWithValue(storage),
        appConfigProvider.overrideWithValue(_config(devInitData: devInitData)),
        localStorageProvider
            .overrideWithValue(localStorage ?? InMemoryStorage()),
        guestAuthEnabledProvider.overrideWithValue(guestAuthEnabled),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('AccessTokenClaims decodes sub/tid/exp and rejects garbage', () {
    final claims = AccessTokenClaims.decode(
      fakeJwt(sub: 'u9', tid: '77', exp: inOneHour()),
    );
    expect(claims, isNotNull);
    expect(claims!.userId, 'u9');
    expect(claims.telegramId, '77');
    expect(claims.isFresh, isTrue);

    expect(AccessTokenClaims.decode('garbage'), isNull);
    expect(AccessTokenClaims.decode('a.b'), isNull);
    expect(AccessTokenClaims.decode('a.!!!.c'), isNull);
  });

  test(
    'bootstrap inside Telegram: verifies via backend and stores the token',
    () async {
      final repo = _FakeAuthRepository(Success(_login()));
      final storage = _MemorySecureStorage();
      final c = make(
        repo: repo,
        bridge: _FakeBridge('query_id=AA&hash=xx'),
        storage: storage,
      );

      await c.read(authControllerProvider.notifier).bootstrap();

      final state = c.read(authControllerProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).session.userId, 'u1');
      expect(repo.calls, 1);
      expect(repo.lastInitData, 'query_id=AA&hash=xx');
      expect(storage.map['auth.access_token'], isNotEmpty);
    },
  );

  test(
    'bootstrap reuses a stored fresh token without a network call',
    () async {
      final repo = _FakeAuthRepository(Success(_login()));
      final storage = _MemorySecureStorage();
      storage.map['auth.access_token'] = fakeJwt(
        sub: 'u5',
        tid: '55',
        exp: inOneHour(),
      );
      final c = make(repo: repo, bridge: _FakeBridge(null), storage: storage);

      await c.read(authControllerProvider.notifier).bootstrap();

      final state = c.read(authControllerProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).session.userId, 'u5');
      expect(repo.calls, 0);
    },
  );

  test(
    'an expired stored token is discarded and a fresh login attempted',
    () async {
      final repo = _FakeAuthRepository(Success(_login(userId: 'u-new')));
      final storage = _MemorySecureStorage();
      storage.map['auth.access_token'] = fakeJwt(
        sub: 'u-old',
        tid: '11',
        exp: DateTime.now()
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final c = make(
        repo: repo,
        bridge: _FakeBridge('fresh=1&hash=xx'),
        storage: storage,
      );

      await c.read(authControllerProvider.notifier).bootstrap();

      expect(repo.calls, 1);
      expect(
        (c.read(authControllerProvider) as Authenticated).session.userId,
        'u-new',
      );
    },
  );

  test(
    'outside Telegram with no seam: calm Unauthenticated, zero requests',
    () async {
      final repo = _FakeAuthRepository(Success(_login()));
      final c = make(
        repo: repo,
        bridge: _FakeBridge(null),
        storage: _MemorySecureStorage(),
      );

      await c.read(authControllerProvider.notifier).bootstrap();

      final state = c.read(authControllerProvider);
      expect(state, isA<Unauthenticated>());
      expect(
        (state as Unauthenticated).reason,
        UnauthenticatedReason.outsideTelegram,
      );
      expect(repo.calls, 0);
    },
  );

  test(
    'the development seam supplies initData outside Telegram — still backend-verified',
    () async {
      final repo = _FakeAuthRepository(Success(_login()));
      final c = make(
        repo: repo,
        bridge: _FakeBridge(null),
        storage: _MemorySecureStorage(),
        devInitData: 'dev=1&hash=xx',
      );

      await c.read(authControllerProvider.notifier).bootstrap();

      expect(repo.lastInitData, 'dev=1&hash=xx');
      expect(c.read(authControllerProvider), isA<Authenticated>());
    },
  );

  test(
    'a rejected login maps to Unauthenticated(rejected) and stores nothing',
    () async {
      final repo = _FakeAuthRepository(
        const ResultFailure(
          AppFailure(
            kind: FailureKind.unauthorized,
            messageKey: 'errorUnauthorized',
          ),
        ),
      );
      final storage = _MemorySecureStorage();
      final c = make(
        repo: repo,
        bridge: _FakeBridge('stale=1&hash=xx'),
        storage: storage,
      );

      await c.read(authControllerProvider.notifier).bootstrap();

      final state = c.read(authControllerProvider);
      expect((state as Unauthenticated).reason, UnauthenticatedReason.rejected);
      expect(storage.map, isEmpty);
    },
  );

  test(
    'a network failure maps to Unauthenticated(network) — retry meaningful',
    () async {
      final repo = _FakeAuthRepository(
        const ResultFailure(
          AppFailure(
            kind: FailureKind.networkUnavailable,
            messageKey: 'errorNetworkUnavailable',
          ),
        ),
      );
      final c = make(
        repo: repo,
        bridge: _FakeBridge('x=1&hash=xx'),
        storage: _MemorySecureStorage(),
      );

      await c.read(authControllerProvider.notifier).bootstrap();

      expect(
        (c.read(authControllerProvider) as Unauthenticated).reason,
        UnauthenticatedReason.network,
      );

      repo.result = Success(_login());
      await c.read(authControllerProvider.notifier).retry();
      expect(c.read(authControllerProvider), isA<Authenticated>());
    },
  );

  test(
    'a backend 401 signal drops the token and re-establishes the session',
    () async {
      final repo = _FakeAuthRepository(Success(_login()));
      final storage = _MemorySecureStorage();
      final c = make(
        repo: repo,
        bridge: _FakeBridge('x=1&hash=xx'),
        storage: storage,
      );

      await c.read(authControllerProvider.notifier).bootstrap();
      expect(repo.calls, 1);

      repo.result = Success(_login(userId: 'u-again'));
      c.read(sessionEventsProvider).notifyUnauthorized();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repo.calls, 2);
      expect(
        (c.read(authControllerProvider) as Authenticated).session.userId,
        'u-again',
      );
    },
  );

  test('AccessTokenClaims tolerates a guest token with no tid', () {
    final claims = AccessTokenClaims.decode(
      fakeJwt(sub: 'g9', exp: inOneHour()),
    );
    expect(claims, isNotNull);
    expect(claims!.userId, 'g9');
    expect(claims.telegramId, isNull);
    expect(claims.isFresh, isTrue);
  });

  test(
    'guest build outside Telegram: signs in with a stable device id',
    () async {
      final repo = _FakeAuthRepository(Success(_guestLogin()));
      final prefs = InMemoryStorage();
      final c = make(
        repo: repo,
        bridge: _FakeBridge(null),
        storage: _MemorySecureStorage(),
        localStorage: prefs,
        guestAuthEnabled: true,
      );

      await c.read(authControllerProvider.notifier).bootstrap();

      final state = c.read(authControllerProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).session.telegramId, isNull);
      expect(repo.guestCalls, 1);
      expect(repo.calls, 0);
      expect(repo.lastDeviceId, isNotEmpty);
      expect(prefs.getString('pref.guest_device_id'), repo.lastDeviceId);
    },
  );

  test('the guest device id is minted once and then reused', () async {
    final repo = _FakeAuthRepository(Success(_guestLogin()));
    final prefs = InMemoryStorage();
    await prefs.setString('pref.guest_device_id', 'existing-device-id-123');
    final c = make(
      repo: repo,
      bridge: _FakeBridge(null),
      storage: _MemorySecureStorage(),
      localStorage: prefs,
      guestAuthEnabled: true,
    );

    await c.read(authControllerProvider.notifier).bootstrap();

    expect(repo.lastDeviceId, 'existing-device-id-123');
    expect(prefs.getString('pref.guest_device_id'), 'existing-device-id-123');
  });

  test('Telegram wins over guest when initData is available', () async {
    final repo = _FakeAuthRepository(Success(_login()));
    final c = make(
      repo: repo,
      bridge: _FakeBridge('query_id=AA&hash=xx'),
      storage: _MemorySecureStorage(),
      guestAuthEnabled: true,
    );

    await c.read(authControllerProvider.notifier).bootstrap();

    expect(repo.calls, 1);
    expect(repo.guestCalls, 0);
  });

  test(
    'without the guest switch, outside Telegram stays a calm dead end',
    () async {
      final repo = _FakeAuthRepository(Success(_guestLogin()));
      final c = make(
        repo: repo,
        bridge: _FakeBridge(null),
        storage: _MemorySecureStorage(),
      );

      await c.read(authControllerProvider.notifier).bootstrap();

      expect(c.read(authControllerProvider), isA<Unauthenticated>());
      expect(repo.guestCalls, 0);
    },
  );

  test('signOut clears the stored token and ends the session', () async {
    final repo = _FakeAuthRepository(Success(_login()));
    final storage = _MemorySecureStorage();
    final c = make(
      repo: repo,
      bridge: _FakeBridge('x=1&hash=xx'),
      storage: storage,
    );

    await c.read(authControllerProvider.notifier).bootstrap();
    expect(storage.map, isNotEmpty);

    await c.read(authControllerProvider.notifier).signOut();
    expect(storage.map, isEmpty);
    expect(c.read(authControllerProvider), isA<Unauthenticated>());
  });
}
