import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/profile/domain/user_profile.dart';

void main() {
  group('stripLeadingName (share privacy, scope §16)', () {
    test('removes the «نام، » greeting from the start', () {
      expect(
        stripLeadingName('علی، امروز روز توست.', 'علی'),
        'امروز روز توست.',
      );
    });

    test('leaves text alone when there is no name', () {
      expect(stripLeadingName('امروز روز توست.', null), 'امروز روز توست.');
      expect(stripLeadingName('امروز روز توست.', '  '), 'امروز روز توست.');
    });

    test('leaves text alone when it does not start with the greeting', () {
      expect(stripLeadingName('امروز روز توست.', 'علی'), 'امروز روز توست.');
    });

    test('a longer word that merely starts with the name is untouched', () {
      expect(
        stripLeadingName('علیرضا، امروز روز توست.', 'علی'),
        'علیرضا، امروز روز توست.',
      );
    });

    test('surrounding spaces in the stored name are ignored', () {
      expect(stripLeadingName('علی، سلام', ' علی '), 'سلام');
    });
  });

  group('birthMonthFa', () {
    test('maps enum names to Persian months', () {
      expect(birthMonthFa('FARVARDIN'), 'فروردین');
      expect(birthMonthFa('MEHR'), 'مهر');
      expect(birthMonthFa('ESFAND'), 'اسفند');
    });

    test('unknown or missing values resolve to null', () {
      expect(birthMonthFa('JANUARY'), isNull);
      expect(birthMonthFa(null), isNull);
    });
  });

  test('UserProfile.fromJson tolerates missing fields', () {
    final p = UserProfile.fromJson(const {});
    expect(p.displayName, isNull);
    expect(p.birthMonth, isNull);
    expect(p.onboardingCompleted, isFalse);
  });
}
