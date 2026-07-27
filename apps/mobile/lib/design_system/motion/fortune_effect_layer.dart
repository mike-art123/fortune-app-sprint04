import 'package:flutter/widgets.dart';

import '../foundations/fortune_focus.dart';
import 'ambient_motion.dart';
import 'fortune_effect_painter.dart';
import 'fortune_effects.dart';

/// The living layer over a fortune card's artwork.
///
/// Sits between the image and its scrim inside `FortuneArt`, so the text and
/// badges above never fight the motion. It draws only when the card has a
/// spec; without an [AmbientMotion] ancestor, or when the platform asks for
/// reduced motion, it paints one quiet still frame — never a ticker of its
/// own, so no existing screen or test gains an animation it did not order.
class FortuneEffectLayer extends StatelessWidget {
  const FortuneEffectLayer({
    super.key,
    required this.id,
    required this.accent,
  });

  final String id;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final spec = fortuneEffectSpec(id);
    if (spec == null) return const SizedBox.shrink();
    final media = MediaQuery.maybeOf(context);
    final reduced = media?.disableAnimations ?? false;
    final clock = reduced ? null : AmbientMotion.maybeClockOf(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: FortuneEffectPainter(
            spec: spec,
            accent: accent,
            seed: effectSeedFor(id),
            alignment: fortuneFocalAlignment(id),
            clock: clock,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
