import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Editorial layout tokens for the fortune redesign. Centralises page margins,
/// section rhythm, card gaps, aspect ratios and the desktop content cap so no
/// screen hardcodes composition values. Additive — spacing/radius scales stay.
abstract final class AppLayout {
  /// Horizontal page padding (mobile-first).
  static const double pageMargin = 18;

  /// Gap between major sections (title + content blocks).
  static const double sectionGap = 30;

  /// Gap between a section heading and its content.
  static const double headingGap = 14;

  /// Gap between cards in a rail or grid.
  static const double cardGap = 14;

  /// Content is centred and capped on wide browsers so mobile cards keep their
  /// proportions instead of stretching edge to edge.
  static const double maxContentWidth = 560;

  // ── Card aspect ratios (width / height) ──
  static const double featuredWide = 16 / 9; // ≈1.78 hero fortune
  static const double sectionFeature = 2.0; // wide thematic band
  static const double portrait = 0.78; // two-column discovery card
  static const double compactLandscape = 4 / 3; // ≈1.33 horizontal rail
  static const double continueReading = 3.4; // wide + shallow module

  // ── Corner radii tuned per card weight ──
  static const double radiusFeatured = 26;
  static const double radiusPortrait = 22;
  static const double radiusCompact = 18;

  /// Curated rail card width as a fraction of the viewport, so the next card
  /// peeks. Clamped to a sensible pixel range for large screens.
  static const double railWidthFraction = 0.76;
  static const double railWidthMax = 300;

  /// Standard soft elevation for image-led cards (no gold outline).
  static List<BoxShadow> get cardShadow {
    return const [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ];
  }

  /// A hairline inner highlight that reads as craft, not a boxed border.
  static Border get innerHairline {
    return Border.all(
      color: AppPalette.goldHi.withValues(alpha: 0.10),
      width: 1,
    );
  }
}
