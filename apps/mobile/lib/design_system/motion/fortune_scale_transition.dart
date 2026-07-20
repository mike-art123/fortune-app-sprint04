import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../foundations/app_curves.dart';
import '../foundations/app_duration.dart';

/// Subtle scale used for reveals. Never bouncy — the register stays calm.
class FortuneScaleIn extends StatelessWidget {
  const FortuneScaleIn({super.key, required this.child, this.from = 0.98});
  final Widget child;
  final double from;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from, end: 1),
      duration: AppDuration.deliberate,
      curve: AppCurves.outExpo,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
