import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';

void main() {
  test('stored preference wins', () {
    expect(
      SupportedLocales.resolve('en', const Locale('fa')),
      SupportedLocales.en,
    );
  });

  test('system locale is used when nothing is stored', () {
    expect(
      SupportedLocales.resolve(null, const Locale('en')),
      SupportedLocales.en,
    );
  });

  test('unsupported system locale falls back to Persian', () {
    expect(
      SupportedLocales.resolve(null, const Locale('de')),
      SupportedLocales.fa,
    );
  });

  test('Persian is the default with no signals', () {
    expect(SupportedLocales.resolve(null, null), SupportedLocales.fa);
  });
}
