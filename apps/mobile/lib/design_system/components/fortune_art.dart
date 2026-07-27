import 'package:flutter/material.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_layout.dart';
import '../foundations/fortune_focus.dart';
import '../motion/fortune_effect_layer.dart';

/// The image layer shared by every fortune card: the approved artwork filling
/// the card with a per-asset focal crop, plus an optional bottom scrim so text
/// stays legible. Never a small framed thumbnail — the art *is* the surface.
class FortuneArt extends StatelessWidget {
  const FortuneArt({
    super.key,
    required this.id,
    required this.accent,
    this.scrim = true,
    this.scrimStrength = 0.82,
  });

  final String id;
  final Color accent;
  final bool scrim;
  final double scrimStrength;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/fortunes/$id.jpg',
          fit: BoxFit.cover,
          alignment: fortuneFocalAlignment(id),
          errorBuilder: (context, error, stack) => _fallback(),
        ),
        // The living layer: ambient motion anchored to this artwork's own
        // geometry. Still when there is no AmbientMotion above, or when
        // the platform asks for reduced motion.
        FortuneEffectLayer(id: id, accent: accent),
        if (scrim)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: scrimStrength),
                ],
                stops: const [0.35, 0.62, 1.0],
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [
            accent.withValues(alpha: 0.42),
            AppPalette.nightPanel,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: AppPalette.goldHi, size: 34),
      ),
    );
  }
}

/// The surface every image-led fortune card sits on: soft drop shadow, rounded
/// clip, ink ripple and a faint inner highlight — deliberately *no* gold
/// outline. Borders are reserved for state (locked/VIP/selected) elsewhere.
class FortuneArtCard extends StatelessWidget {
  const FortuneArtCard({
    super.key,
    required this.radius,
    required this.child,
    this.onTap,
  });

  final double radius;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: AppLayout.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Material(
          color: AppPalette.nightPanel,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: shape,
                        border: AppLayout.innerHairline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
