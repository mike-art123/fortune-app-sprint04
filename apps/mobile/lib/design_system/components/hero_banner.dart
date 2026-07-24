import 'package:flutter/material.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_effects.dart';
import '../foundations/app_gradients.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';
import '../theme/fortune_theme_extension.dart';

/// Cinematic hero: a night-sky arch with a gold crescent, a gold-gradient
/// title, a subtitle and a call-to-action. A raster background scene can be
/// layered behind later; the gradient frame stands on its own until then.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.heroNight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppPalette.goldMid.withValues(alpha: 0.35)),
        boxShadow: AppEffects.goldGlow,
      ),
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
