import 'package:flutter/material.dart';

/// Typography roles (doc 51 §16). Persian-first: generous line height so
/// ascenders/diacritics breathe. Nastaliq is an accent face only and is never
/// used for body or UI text (accessibility failure at small sizes).
abstract final class AppTypography {
  static const String primaryFamily = 'Vazirmatn';

  /// Display face reserved for rare emotional moments (result headline, share
  /// card). Falls back to the primary family until the licensed face ships.
  static const String accentFamily = 'Vazirmatn';

  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle s(double size, FontWeight w, double height, {double? spacing, Color? color}) =>
        TextStyle(
          fontFamily: primaryFamily,
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: spacing,
          color: color ?? primary,
        );

    return TextTheme(
      displayLarge: s(40, FontWeight.w700, 1.25),
      displayMedium: s(32, FontWeight.w700, 1.3),
      headlineLarge: s(28, FontWeight.w600, 1.35),
      headlineMedium: s(24, FontWeight.w600, 1.4),
      titleLarge: s(20, FontWeight.w600, 1.5),
      titleMedium: s(17, FontWeight.w500, 1.5),
      bodyLarge: s(16, FontWeight.w400, 1.85),
      bodyMedium: s(15, FontWeight.w400, 1.8, color: secondary),
      bodySmall: s(13, FontWeight.w400, 1.7, color: secondary),
      labelLarge: s(15, FontWeight.w600, 1.4),
      labelMedium: s(13, FontWeight.w500, 1.4, color: secondary),
      labelSmall: s(12, FontWeight.w400, 1.5, color: secondary),
    );
  }
}
