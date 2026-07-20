import 'package:flutter/material.dart';
import '../foundations/app_curves.dart';
import '../foundations/app_duration.dart';

/// Cross-fades between children without layout jumps.
class FortuneAnimatedPresence extends StatelessWidget {
  const FortuneAnimatedPresence({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppDuration.standard,
    switchInCurve: AppCurves.premium,
    switchOutCurve: AppCurves.premium,
    child: child,
  );
}
