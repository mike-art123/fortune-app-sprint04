import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_gradients.dart';
import '../foundations/app_layout.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';
import 'fortune_art.dart';

/// Editorial fortune card taxonomy. Each shape presents the *same* approved
/// artwork through a different proportion and text weight, so a page reads as a
/// composed spread instead of a grid of identical square tiles. None of these
/// draw a gold outline — depth comes from the image, scrim, shadow and spacing.

// ── shared text styles over artwork ──────────────────────────────────────
TextStyle _titleStyle(double size) {
  return TextStyle(
    color: Colors.white,
    fontSize: size,
    height: 1.15,
    fontWeight: FontWeight.w800,
    shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 8)],
  );
}

TextStyle _descStyle(double size) {
  return TextStyle(
    color: Colors.white.withValues(alpha: 0.82),
    fontSize: size,
    height: 1.25,
    shadows: const [Shadow(color: Color(0xB3000000), blurRadius: 6)],
  );
}

/// A discreet coin / free indicator — small by design (spec: no large labels).
class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadiusPill._pill),
        border: Border.all(
          color: (tone ?? AppPalette.goldHi).withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: tone ?? AppPalette.goldHi,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Local pill radius (kept private so tokens file stays the source of truth).
abstract final class AppRadiusPill {
  static const double _pill = 999;
}

/// Small gold CTA used on the featured card.
class _CtaPill extends StatelessWidget {
  const _CtaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.goldSheen,
        borderRadius: BorderRadius.circular(AppRadiusPill._pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: AppPalette.nightDeep,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// 1 — full-width hero fortune (16:9), title + one line + CTA.
/// A small diagonal «ویژه» band across the top-right corner — reserved for
/// the coffee reading, the house specialty. Clipped by the card's own
/// rounded clip, so it reads as a stitched ribbon rather than a sticker.
class _SpecialRibbon extends StatelessWidget {
  const _SpecialRibbon();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: -26,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: 0.7854,
          child: Container(
            width: 96,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE5484D), Color(0xFFB3261E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              context.strings.badgeSpecial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturedWideFortuneCard extends StatelessWidget {
  const FeaturedWideFortuneCard({
    super.key,
    required this.id,
    required this.title,
    required this.accent,
    required this.onTap,
    this.subtitle,
    this.cta,
  });

  final String id;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  /// Both optional: the artwork already says which fortune this is, so a
  /// card can carry just its name and let the whole surface be the tap
  /// target instead of repeating itself in a subtitle and a button.
  final String? subtitle;
  final String? cta;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppLayout.featuredWide,
      child: FortuneArtCard(
        radius: AppLayout.radiusFeatured,
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(child: FortuneArt(id: id, accent: accent)),
            if (id == 'coffee') const _SpecialRibbon(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _titleStyle(21)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _descStyle(12.5),
                      ),
                    ],
                    if (cta != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _CtaPill(label: cta!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 6 — wide thematic band (2:1) that opens a section with one strong image.
class SectionFeatureCard extends StatelessWidget {
  const SectionFeatureCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppLayout.sectionFeature,
      child: FortuneArtCard(
        radius: AppLayout.radiusFeatured,
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(child: FortuneArt(id: id, accent: accent)),
            if (id == 'coffee') const _SpecialRibbon(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _titleStyle(18)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _descStyle(11.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2 — two-column discovery card (portrait ~0.78), image-led, title low.
class PortraitFortuneCard extends StatelessWidget {
  const PortraitFortuneCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.available,
    required this.soonLabel,
    required this.onTap,
    this.priceLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color accent;
  final bool available;
  final String soonLabel;
  final String? priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppLayout.portrait,
      child: FortuneArtCard(
        radius: AppLayout.radiusPortrait,
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(child: FortuneArt(id: id, accent: accent)),
            if (id == 'coffee') const _SpecialRibbon(),
            if (available && priceLabel != null)
              PositionedDirectional(
                top: AppSpacing.xs,
                start: AppSpacing.xs,
                child: _MetaBadge(label: priceLabel!),
              ),
            if (!available)
              PositionedDirectional(
                top: AppSpacing.xs,
                start: AppSpacing.xs,
                child: _MetaBadge(
                  label: soonLabel,
                  tone: AppPalette.warning,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle(14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _descStyle(10.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3 — horizontal rail card (~4:3), concise metadata. Width set by the rail.
class CompactLandscapeFortuneCard extends StatelessWidget {
  const CompactLandscapeFortuneCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppLayout.compactLandscape,
      child: FortuneArtCard(
        radius: AppLayout.radiusCompact,
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(child: FortuneArt(id: id, accent: accent)),
            if (id == 'coffee') const _SpecialRibbon(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle(14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _descStyle(11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5 — compact quick action: borderless, icon in a soft tonal disc + label.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rounded-square artwork tile, matching the app's card imagery —
          // the emblem fills the tile instead of hiding inside a tiny disc.
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
              gradient: RadialGradient(
                colors: [AppPalette.nightGlow, AppPalette.nightPanel],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: Image.asset(
              asset,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Icon(
                Icons.auto_awesome,
                color: AppPalette.goldHi,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.parchmentInk,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
