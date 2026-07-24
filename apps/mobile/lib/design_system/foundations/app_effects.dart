import 'package:flutter/material.dart';

/// Soft glows and depth shadows for the premium redesign. Additive foundation
/// consumed by the new premium components.
abstract final class AppEffects {
  /// Gentle gold bloom around cards, chips and the hero.
  static const goldGlow = <BoxShadow>[
    BoxShadow(color: Color(0x2ED9A83E), blurRadius: 22),
  ];

  /// Stronger gold bloom for active / focused surfaces.
  static const goldGlowStrong = <BoxShadow>[
    BoxShadow(color: Color(0x47E7C25E), blurRadius: 26, spreadRadius: 1),
  ];

  /// Depth shadow beneath elevated cards.
  static const cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Purple bloom for the bottom-nav orb.
  static const orbGlow = <BoxShadow>[
    BoxShadow(color: Color(0x99966EF0), blurRadius: 26, spreadRadius: 1),
  ];
}
