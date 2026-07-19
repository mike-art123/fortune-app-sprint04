import 'package:flutter/material.dart';
import 'fortune_color_scheme.dart';

/// Ergonomic access to semantic colours: `context.fortuneColors.textPrimary`.
extension FortuneThemeX on BuildContext {
  FortuneColors get fortuneColors =>
      Theme.of(this).extension<FortuneColors>() ?? FortuneColors.dark;
}
