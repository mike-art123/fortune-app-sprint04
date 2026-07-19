import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_strings.dart';

/// Persian is the product default; English is the fallback (doc 51 §13.1).
abstract final class SupportedLocales {
  static const fa = Locale('fa');
  static const en = Locale('en');

  static const all = <Locale>[fa, en];
  static const fallback = fa;

  static const delegates = <LocalizationsDelegate<dynamic>>[
    AppStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Resolves a stored/system locale to a supported one, defaulting to Persian.
  static Locale resolve(String? storedCode, Locale? systemLocale) {
    if (storedCode != null) {
      final match = all.where((l) => l.languageCode == storedCode).firstOrNull;
      if (match != null) return match;
    }
    if (systemLocale != null) {
      final match = all.where((l) => l.languageCode == systemLocale.languageCode).firstOrNull;
      if (match != null) return match;
    }
    return fallback;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
