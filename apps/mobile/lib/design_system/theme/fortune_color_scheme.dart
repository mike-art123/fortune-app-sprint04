import 'package:flutter/material.dart';
import '../foundations/app_colors.dart';

/// Semantic colour roles exposed to features. Features MUST read these
/// (via `context.fortuneColors`) rather than raw palette values, so that light
/// and dark modes stay equivalent and themable.
@immutable
class FortuneColors extends ThemeExtension<FortuneColors> {
  const FortuneColors({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surfacePrimary,
    required this.surfaceElevated,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderSubtle,
    required this.borderStrong,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.goldWarm,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.overlayScrim,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color surfacePrimary;
  final Color surfaceElevated;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderSubtle;
  final Color borderStrong;
  final Color accentPrimary;
  final Color accentSecondary;

  /// Gold is a rare, precious line — never a background fill.
  final Color goldWarm;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color overlayScrim;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static const dark = FortuneColors(
    backgroundPrimary: AppPalette.shab,
    backgroundSecondary: AppPalette.shab2,
    surfacePrimary: AppPalette.shab2,
    surfaceElevated: AppPalette.shab3,
    surfaceSubtle: AppPalette.shab2,
    textPrimary: AppPalette.parchmentInk,
    textSecondary: AppPalette.parchmentInk2,
    textMuted: AppPalette.parchmentInk3,
    borderSubtle: AppPalette.parchmentInk3,
    borderStrong: AppPalette.parchmentInk2,
    accentPrimary: AppPalette.lajvard,
    accentSecondary: AppPalette.firuzeh,
    goldWarm: AppPalette.tala,
    success: AppPalette.success,
    warning: AppPalette.warning,
    error: AppPalette.error,
    info: AppPalette.info,
    overlayScrim: Color(0xCC0E1230),
    shimmerBase: AppPalette.shab2,
    shimmerHighlight: AppPalette.shab3,
  );

  static const light = FortuneColors(
    backgroundPrimary: AppPalette.kaghaz,
    backgroundSecondary: AppPalette.kaghaz2,
    surfacePrimary: AppPalette.kaghaz2,
    surfaceElevated: Colors.white,
    surfaceSubtle: AppPalette.kaghaz,
    textPrimary: AppPalette.midnightInk,
    textSecondary: AppPalette.midnightInk2,
    textMuted: AppPalette.midnightInk3,
    borderSubtle: AppPalette.midnightInk3,
    borderStrong: AppPalette.midnightInk2,
    accentPrimary: AppPalette.lajvard,
    accentSecondary: Color(0xFF1E8F88),
    goldWarm: AppPalette.talaLight,
    success: Color(0xFF2A8560),
    warning: Color(0xFFB07828),
    error: Color(0xFFA8455A),
    info: Color(0xFF3B6BA8),
    overlayScrim: Color(0x99171A2E),
    shimmerBase: AppPalette.kaghaz,
    shimmerHighlight: Colors.white,
  );

  @override
  FortuneColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? surfacePrimary,
    Color? surfaceElevated,
    Color? surfaceSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? borderSubtle,
    Color? borderStrong,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? goldWarm,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? overlayScrim,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return FortuneColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      goldWarm: goldWarm ?? this.goldWarm,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      overlayScrim: overlayScrim ?? this.overlayScrim,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  FortuneColors lerp(ThemeExtension<FortuneColors>? other, double t) {
    if (other is! FortuneColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return FortuneColors(
      backgroundPrimary: c(backgroundPrimary, other.backgroundPrimary),
      backgroundSecondary: c(backgroundSecondary, other.backgroundSecondary),
      surfacePrimary: c(surfacePrimary, other.surfacePrimary),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceSubtle: c(surfaceSubtle, other.surfaceSubtle),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderStrong: c(borderStrong, other.borderStrong),
      accentPrimary: c(accentPrimary, other.accentPrimary),
      accentSecondary: c(accentSecondary, other.accentSecondary),
      goldWarm: c(goldWarm, other.goldWarm),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      error: c(error, other.error),
      info: c(info, other.info),
      overlayScrim: c(overlayScrim, other.overlayScrim),
      shimmerBase: c(shimmerBase, other.shimmerBase),
      shimmerHighlight: c(shimmerHighlight, other.shimmerHighlight),
    );
  }
}
