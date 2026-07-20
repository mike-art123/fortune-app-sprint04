import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../foundations/app_curves.dart';
import '../foundations/app_duration.dart';

/// Fade + slight rise. Honors reduce-motion by falling back to a plain fade.
class FortuneFadeIn extends StatelessWidget {
  const FortuneFadeIn({
    super.key,
    required this.child,
    this.duration = AppDuration.standard,
    this.offset = 12,
  });

  final Widget child;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduce ? AppDuration.instant : duration,
      curve: AppCurves.premium,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: reduce
            ? child
            : Transform.translate(
                offset: Offset(0, offset * (1 - t)),
                child: child,
              ),
      ),
      child: child,
    );
  }
}
