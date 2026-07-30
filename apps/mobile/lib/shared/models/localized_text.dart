import 'package:flutter/material.dart';

/// Locale-aware copy owned by domain data (e.g. the fortune registry).
/// Keeps user-visible strings centralized without widget hardcoding.
///
/// Arabic and Turkish are optional while the catalog is being translated;
/// until a string arrives they fall back to English (closer register for
/// both audiences than Persian script they may not read).
class LocalizedText {
  const LocalizedText({required this.fa, required this.en, this.ar, this.tr});

  final String fa;
  final String en;
  final String? ar;
  final String? tr;

  String resolve(Locale locale) {
    return switch (locale.languageCode) {
      'en' => en,
      'ar' => ar ?? en,
      'tr' => tr ?? en,
      _ => fa,
    };
  }
}
