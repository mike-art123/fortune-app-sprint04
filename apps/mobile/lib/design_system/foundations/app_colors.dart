import 'package:flutter/material.dart';

/// Raw palette values for the "Illuminated Sky" direction (Constitution §14,
/// Visual Design Report). These are primitives only — features MUST consume the
/// semantic roles from [FortuneColors] via the theme extension, never these.
abstract final class AppPalette {
  // Night (dark theme base)
  static const shab = Color(0xFF0E1230);
  static const shab2 = Color(0xFF161A3C);
  static const shab3 = Color(0xFF1E244E);

  // Manuscript (light theme base)
  static const kaghaz = Color(0xFFF5EFE2);
  static const kaghaz2 = Color(0xFFFBF7EE);

  // Persian identity
  static const lajvard = Color(0xFF23408F); // lapis
  static const firuzeh = Color(0xFF2FB6AE); // turquoise
  static const tala = Color(0xFFCBA45A); // warm restrained gold
  static const talaLight = Color(0xFFB08028);
  static const zafaran = Color(0xFFE0A23C); // saffron
  static const goleSorkh = Color(0xFFB4587A); // Persian rose

  // Ink
  static const parchmentInk = Color(0xFFEDE8DB);
  static const parchmentInk2 = Color(0xFF9AA0B8);
  static const parchmentInk3 = Color(0xFF6E748E);
  static const midnightInk = Color(0xFF171A2E);
  static const midnightInk2 = Color(0xFF55527A);
  static const midnightInk3 = Color(0xFF8C8AA5);

  // Status
  static const success = Color(0xFF3FA37A);
  static const warning = Color(0xFFD9A441);
  static const error = Color(0xFFC2566A);
  static const info = Color(0xFF5A86C7);

  // ── Luxury redesign primitives (BakhtNegar premium reference). Additive:
  // existing semantic roles are unchanged so current screens keep working.
  static const goldHi = Color(0xFFF6DF9A);
  static const goldBright = Color(0xFFE7C25E);
  static const goldMid = Color(0xFFD9A83E);
  static const goldDeep = Color(0xFFA9782A);
  static const nightDeep = Color(0xFF05070F);
  static const nightPanel = Color(0xFF0D1732);
  static const nightGlow = Color(0xFF16204A);
  static const gem = Color(0xFFA78BFA);
  static const gemDeep = Color(0xFF7C5CC4);
}

/// Per-fortune accent colours. One dominant accent per screen (Visual Report).
abstract final class CategoryAccents {
  static const hafez = AppPalette.tala;
  static const tarot = AppPalette.firuzeh;
  static const dream = Color(0xFF8FB3E0);
  static const love = AppPalette.goleSorkh;
  static const coffee = Color(0xFFBE8C69);
}
