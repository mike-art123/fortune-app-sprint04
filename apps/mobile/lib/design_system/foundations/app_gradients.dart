import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Luxury gradients for the premium redesign (BakhtNegar visual reference).
/// Additive foundation consumed by the new premium components — existing
/// screens are untouched.
abstract final class AppGradients {
  /// Warm metallic gold — CTAs, wordmarks, active accents.
  static const goldSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.goldHi, AppPalette.goldBright, AppPalette.goldDeep],
    stops: [0.0, 0.5, 1.0],
  );

  /// Cinematic night sky for the hero banner.
  static const heroNight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A2150), Color(0xFF111741), Color(0xFF0A1030)],
  );

  /// Dark premium card fill.
  static const cardLuxe = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF101A38), Color(0xFF0A1126)],
  );

  /// Purple-navy reward / VIP banner wash.
  static const rewardWash = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF241A44), Color(0xFF141031), Color(0xFF1C1436)],
  );

  /// App background halo — deep night with a navy glow near the top.
  static const screenGlow = RadialGradient(
    center: Alignment(0.0, -1.1),
    radius: 1.2,
    colors: [AppPalette.nightGlow, AppPalette.nightDeep],
    stops: [0.0, 0.7],
  );
}
