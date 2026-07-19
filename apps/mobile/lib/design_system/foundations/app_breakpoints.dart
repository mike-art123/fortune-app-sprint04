/// Layout breakpoints (doc 51 §20). Use constraints, not device checks.
abstract final class AppBreakpoints {
  static const double compact = 360;
  static const double medium = 480;
  static const double expanded = 840;

  /// Long-form reading must not stretch edge-to-edge on wide screens.
  static const double maxReadableWidth = 560;
}
