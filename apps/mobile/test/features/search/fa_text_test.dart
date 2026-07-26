import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/search/domain/fa_text.dart';

/// Persian folding (scope §2): the same intention, typed in any of the ways a
/// real keyboard produces it, must reduce to one canonical form.
void main() {
  group('faNormalize', () {
    test('folds the Arabic ي and ك onto the Persian letters', () {
      expect(faNormalize('كتاب'), faNormalize('کتاب'));
      expect(faNormalize('حافظي'), faNormalize('حافظی'));
    });

    test('folds alef shapes and the ta marbuta', () {
      expect(faNormalize('آینه'), faNormalize('اینه'));
      expect(faNormalize('إستخاره'), faNormalize('استخاره'));
      expect(faNormalize('ملائكة'), faNormalize('ملائکه'));
    });

    test('نیم‌فاصله and other zero-width marks become word boundaries', () {
      expect(faNormalize('نیم‌فاصله'), 'نیم فاصله');
      expect(faNormalize('به‌زودی'), 'به زودی');
    });

    test('drops tashkeel and tatweel', () {
      expect(faNormalize('حَافِظ'), 'حافظ');
      expect(faNormalize('حــافظ'), 'حافظ');
    });

    test('folds Persian and Arabic digits onto ASCII', () {
      expect(faNormalize('۱۳۵'), '135');
      expect(faNormalize('٤٢'), '42');
    });

    test('punctuation and emoji are boundaries, spaces collapse', () {
      expect(faNormalize('  فال،  حافظ!  '), 'فال حافظ');
      expect(faNormalize('فال 🔮 قهوه'), 'فال قهوه');
    });

    test('latin is lowercased and kept', () {
      expect(faNormalize('Hafez'), 'hafez');
    });

    test('empty and symbol-only input normalize to empty', () {
      expect(faNormalize(''), '');
      expect(faNormalize('؟!.'), '');
    });
  });

  group('faTokens', () {
    test('splits the normalized form into words', () {
      expect(faTokens('فال  حافظ'), ['فال', 'حافظ']);
      expect(faTokens('   '), isEmpty);
    });
  });

  group('faEditDistance', () {
    test('counts a single typo', () {
      expect(faEditDistance('حافظ', 'حافز', ceiling: 2), 1);
      expect(faEditDistance('tarot', 'tarrot', ceiling: 2), 1);
    });

    test('identical strings cost nothing', () {
      expect(faEditDistance('قهوه', 'قهوه', ceiling: 1), 0);
    });

    test('stops early once the ceiling is passed', () {
      final distance = faEditDistance('مدیتیشن', 'قهوه', ceiling: 2);
      expect(distance, greaterThan(2));
    });
  });
}
