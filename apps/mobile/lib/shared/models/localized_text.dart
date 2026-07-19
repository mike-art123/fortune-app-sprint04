import 'package:flutter/material.dart';

/// Locale-aware copy owned by domain data (e.g. the fortune registry).
/// Keeps user-visible strings centralized without widget hardcoding.
class LocalizedText {
  const LocalizedText({required this.fa, required this.en});
  final String fa;
  final String en;

  String resolve(Locale locale) => locale.languageCode == 'en' ? en : fa;
}
