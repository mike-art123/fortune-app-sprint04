/// Motion durations (doc 51 §18). Calm over dramatic.
abstract final class AppDuration {
  static const instant = Duration(milliseconds: 100);
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 260);
  static const deliberate = Duration(milliseconds: 420);
  /// Reserved for ritual moments only, where the pause carries meaning.
  static const ritual = Duration(milliseconds: 750);
}
