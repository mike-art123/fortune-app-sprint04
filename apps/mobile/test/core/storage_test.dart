import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/constants/app_constants.dart';
import 'package:fortune_app/core/constants/storage_keys.dart';
import 'package:fortune_app/core/persistence/local_storage.dart';
import 'package:fortune_app/core/persistence/storage_migrations.dart';

void main() {
  test('migration stamps the current storage version', () async {
    final storage = InMemoryStorage();
    await StorageMigrations(storage).run();
    expect(storage.getInt(PrefKeys.storageVersion), AppConstants.storageVersion);
  });

  test('migration is idempotent', () async {
    final storage = InMemoryStorage();
    await StorageMigrations(storage).run();
    await StorageMigrations(storage).run();
    expect(storage.getInt(PrefKeys.storageVersion), AppConstants.storageVersion);
  });
}
