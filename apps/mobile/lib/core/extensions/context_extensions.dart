import 'package:flutter/material.dart';

/// Ergonomic access to theme/media values.
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textStyles => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Respect the platform reduce-motion setting (doc 51 §18/§34).
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
