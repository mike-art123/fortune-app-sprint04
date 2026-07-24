import 'package:flutter/material.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_effects.dart';
import '../foundations/app_gradients.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';
import '../theme/fortune_theme_extension.dart';

/// Cinematic hero: a night-sky arch with a gold-gradient title, a subtitle and
/// a call-to-action. An optional [backgroundAsset] paints a full raster scene
/// behind a readability scrim; without it the gradient frame stands alone.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    this.backgroundAsset,
  });

  final String title;
  final String subtitle;
  final Widget action;
  final String? backgroundAsset;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final bg = backgroundAsset;
    final radius = BorderRadius.circular(AppRadius.xl);

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(
            Icons.nightlight_round,
            size: 34,
            color: AppPalette.goldHi,
          ),
          const SizedBox(height: AppSpacing.sm),
          _GoldTitle(title),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          action,
        ],
      ),
    );

    Widget inner = content;
    if (bg != null) {
      inner = _WithBackground(asset: bg, child: content);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: bg == null ? AppGradients.heroNight : null,
        borderRadius: radius,
        border: Border.all(color: AppPalette.goldMid.withValues(alpha: 0.35)),
        boxShadow: AppEffects.goldGlow,
      ),
      child: ClipRRect(borderRadius: radius, child: inner),
    );
  }
}

class _WithBackground extends StatelessWidget {
  const _WithBackground({required this.asset, required this.child});

  final String asset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.heroNight),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33070B18), Color(0xD90A1030)],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GoldTitle extends StatelessWidget {
  const _GoldTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => AppGradients.goldSheen.createShader(rect),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
