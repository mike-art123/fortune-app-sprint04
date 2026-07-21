import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/wallet/application/wallet_controller.dart';
import 'package:fortune_app/features/wallet/data/entitlement_dto.dart';
import 'package:fortune_app/features/wallet/data/wallet_dto.dart';
import 'package:fortune_app/features/wallet/domain/entitlement_status.dart';
import 'package:fortune_app/features/wallet/domain/wallet_repository.dart';
import 'package:fortune_app/features/wallet/domain/wallet_summary.dart';

void main() {
  group('WalletDto', () {
    test('parses the backend payload', () {
      final summary = WalletDto.fromJson({
        'balance': 28,
        'transactions': [
          {
            'id': 't2',
            'amount': -2,
            'kind': 'spend',
            'reason': null,
            'createdAt': '2026-01-02T10:00:00.000Z',
          },
          {
            'id': 't1',
            'amount': 30,
            'kind': 'starter',
            'reason': 'اعتبار آغازین',
            'createdAt': '2026-01-01T00:00:00.000Z',
          },
        ],
      });

      expect(summary.balance, 28);
      expect(summary.entries, hasLength(2));
      expect(summary.entries.first.isCredit, isFalse);
      expect(summary.entries.last.kind, 'starter');
      expect(summary.entries.last.reason, 'اعتبار آغازین');
    });

    test('rejects a payload without a balance', () {
      expect(
        () => WalletDto.fromJson({'transactions': []}),
        throwsFormatException,
      );
    });

    test('rejects an entry missing required fields', () {
      expect(
        () => WalletDto.fromJson({
          'balance': 1,
          'transactions': [
            {'id': 't1'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('an empty ledger parses to an empty list, never a fake entry', () {
      final summary = WalletDto.fromJson({'balance': 0, 'transactions': []});
      expect(summary.balance, 0);
      expect(summary.entries, isEmpty);
    });
  });

  group('EntitlementDto', () {
    test('parses coverage and cost', () {
      final e = EntitlementDto.fromJson({
        'covered': true,
        'source': 'subscription',
        'cost': 0,
      });
      expect(e.hasActiveSubscription, isTrue);
      expect(e.cost, 0);

      final p = EntitlementDto.fromJson({
        'covered': false,
        'source': null,
        'cost': 5,
      });
      expect(p.hasActiveSubscription, isFalse);
      expect(p.cost, 5);
    });

    test('rejects a malformed payload', () {
      expect(
        () => EntitlementDto.fromJson({'covered': 'yes'}),
        throwsFormatException,
      );
    });
  });

  group('WalletController', () {
    ProviderContainer container(WalletRepository repo) {
      final c = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('loads and exposes the backend balance untouched', () async {
      final c = container(
        _FakeWalletRepository(
          Success(const WalletSummary(balance: 30, entries: [])),
        ),
      );

      final sub = c.listen(walletControllerProvider, (_, __) {});
      expect(sub.read(), isA<WalletLoading>());
      await settle();

      final state = sub.read();
      expect(state, isA<WalletLoaded>());
      expect((state as WalletLoaded).summary.balance, 30);
    });

    test(
      'exposes the backend entitlement next to the wallet (Sprint 04)',
      () async {
        final c = container(
          _FakeWalletRepository(
            Success(const WalletSummary(balance: 30, entries: [])),
            entitlementResult: Success(
              const EntitlementStatus(
                covered: true,
                source: 'subscription',
                cost: 0,
              ),
            ),
          ),
        );

        final sub = c.listen(walletControllerProvider, (_, __) {});
        await settle();

        final state = sub.read() as WalletLoaded;
        expect(state.entitlement?.hasActiveSubscription, isTrue);
      },
    );

    test(
      'a failed entitlement lookup never blocks the wallet itself',
      () async {
        final c = container(
          _FakeWalletRepository(
            Success(const WalletSummary(balance: 30, entries: [])),
            entitlementResult: const ResultFailure(
              AppFailure(kind: FailureKind.server, messageKey: 'errorGeneric'),
            ),
          ),
        );

        final sub = c.listen(walletControllerProvider, (_, __) {});
        await settle();

        final state = sub.read() as WalletLoaded;
        expect(state.summary.balance, 30);
        expect(state.entitlement, isNull);
      },
    );

    test('surfaces a typed failure and recovers on retry', () async {
      final repo = _FakeWalletRepository(
        ResultFailure(
          const AppFailure(kind: FailureKind.server, messageKey: 'x'),
        ),
      );
      final c = container(repo);

      final sub = c.listen(walletControllerProvider, (_, __) {});
      await settle();
      expect(sub.read(), isA<WalletFailed>());

      repo.result = Success(const WalletSummary(balance: 30, entries: []));
      await c.read(walletControllerProvider.notifier).retry();

      expect(sub.read(), isA<WalletLoaded>());
    });
  });
}

class _FakeWalletRepository implements WalletRepository {
  _FakeWalletRepository(this.result, {this.entitlementResult});
  Result<WalletSummary> result;
  Result<EntitlementStatus>? entitlementResult;

  @override
  Future<Result<WalletSummary>> fetch() async => result;

  @override
  Future<Result<EntitlementStatus>> entitlement() async =>
      entitlementResult ??
      Success(const EntitlementStatus(covered: false, source: null, cost: 5));
}
