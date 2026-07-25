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

  /// Resolves the active locale. BakhtNegar is Persian-first: only an explicit
  /// in-app choice (the stored preference) may switch the language — a device
  /// set to English must NOT flip the whole experience to English. The system
  /// locale is deliberately ignored until a real language switcher ships.
  static Locale resolve(String? storedCode, Locale? systemLocale) {
    if (storedCode != null) {
      final match = all.where((l) => l.languageCode == storedCode).firstOrNull;
      if (match != null) return match;
    }
    return fallback;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
