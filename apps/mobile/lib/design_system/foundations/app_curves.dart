import 'package:flutter/animation.dart';

/// Easing curves. No bounce, no playful spring — the register is celestial.
abstract final class AppCurves {
  static const premium = Cubic(0.2, 0.8, 0.2, 1.0);
  static const outExpo = Cubic(0.16, 1.0, 0.3, 1.0);
  static const standard = Curves.easeOutCubic;
}
