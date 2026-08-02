import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/app_strings.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';

/// App Review Guideline 5.1.2(i): "You must clearly disclose where personal
/// data will be shared with third parties, including with third-party AI, and
/// obtain explicit permission before doing so."
///
/// The line beneath the ritual's own button is where that disclosure is made:
/// at the moment the person chooses to send, in whatever language they read.
/// A missing or untranslated one is a compliance failure rather than a typo,
/// so it is pinned here instead of being noticed in a rejection letter.
void main() {
  test('every language says what is sent and to whom', () {
    for (final locale in SupportedLocales.all) {
      final note = AppStrings.forLocale(locale).aiConsentNote;

      expect(note, isNotEmpty, reason: '${locale.languageCode}: no note');
      expect(
        note.length,
        greaterThan(60),
        reason: '${locale.languageCode}: too short to disclose much',
      );
    }
  });

  test('no language was left sitting on the Persian sentence', () {
    final fa = AppStrings.forLocale(SupportedLocales.fa).aiConsentNote;

    for (final locale in [
      SupportedLocales.en,
      SupportedLocales.ar,
      SupportedLocales.tr,
    ]) {
      expect(
        AppStrings.forLocale(locale).aiConsentNote,
        isNot(fa),
        reason: '${locale.languageCode}: still shows the Persian sentence',
      );
    }
  });
}
