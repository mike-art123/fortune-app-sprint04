import 'package:flutter/material.dart';
import '../../design_system/foundations/app_colors.dart';
import '../../design_system/foundations/app_typography.dart';
import '../../design_system/theme/fortune_color_scheme.dart';

/// Builds ThemeData from the Illuminated Sky tokens. Semantic roles are carried
/// by the [FortuneColors] extension so both modes stay equivalent (doc 51 §43).
abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, FortuneColors.dark);
  static ThemeData light() => _build(Brightness.light, FortuneColors.light);

  static ThemeData _build(Brightness brightness, FortuneColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accentPrimary,
      onPrimary: brightness == Brightness.dark
          ? AppPalette.parchmentInk
          : Colors.white,
      secondary: c.accentSecondary,
      onSecondary:
          brightness == Brightness.dark ? AppPalette.shab : Colors.white,
      error: c.error,
      onError: Colors.white,
      surface: c.surfacePrimary,
      onSurface: c.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.backgroundPrimary,
      canvasColor: c.backgroundPrimary,
      fontFamily: AppTypography.primaryFamily,
      textTheme: AppTypography.textTheme(c.textPrimary, c.textSecondary),
      dividerTheme: DividerThemeData(
        color: c.borderSubtle.withValues(alpha: 0.2),
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.backgroundPrimary,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      extensions: <ThemeExtension<dynamic>>[c],
    );
  }
}
