import 'package:flutter/foundation.dart';

/// Reactive holder for the Telegram Mini App safe-area insets (Bot API 8.0+).
///
/// Subclasses read Telegram's raw values (web) or nothing (VM/tests) and call
/// [applyInsets]; widgets listen via [ChangeNotifier]. Outside Telegram every
/// inset stays 0, so normal-browser layout is completely unchanged.
abstract class TelegramSafeArea extends ChangeNotifier {
  double _top = 0;
  double _bottom = 0;
  double _left = 0;
  double _right = 0;

  /// Total desired top inset: device safe area + Telegram controls + a little
  /// breathing room, resolved from the raw values in [applyInsets].
  double get topInset => _top;
  double get bottomInset => _bottom;
  double get leftInset => _left;
  double get rightInset => _right;

  /// Begin listening to Telegram viewport / safe-area events.
  void start();

  /// Recompute the insets from Telegram's raw values and notify on any change.
  void applyInsets({
    required bool available,
    required bool fullscreen,
    required double safeTop,
    required double safeBottom,
    required double safeLeft,
    required double safeRight,
    required double contentTop,
  }) {
    final double top;
    if (!available) {
      // Normal browser (or a Telegram client without the safe-area API):
      // contribute nothing so existing layout is preserved.
      top = 0;
    } else if (fullscreen) {
      final larger = safeTop > contentTop ? safeTop : contentTop;
      top = larger + _breathingRoom;
    } else {
      top = contentTop;
    }

    final nextTop = _clamp(top);
    final nextBottom = _clamp(safeBottom);
    final nextLeft = _clamp(safeLeft);
    final nextRight = _clamp(safeRight);

    final changed = nextTop != _top ||
        nextBottom != _bottom ||
        nextLeft != _left ||
        nextRight != _right;
    if (!changed) return;

    _top = nextTop;
    _bottom = nextBottom;
    _left = nextLeft;
    _right = nextRight;

    if (kDebugMode) {
      debugPrint(
        '[tg-safearea] available=$available fullscreen=$fullscreen '
        'safeTop=$safeTop contentTop=$contentTop => topInset=$_top',
      );
    }
    notifyListeners();
  }

  /// A few logical pixels below Telegram's Close/top controls in fullscreen.
  static const double _breathingRoom = 8;

  static double _clamp(double value) =>
      value.isFinite ? value.clamp(0.0, 160.0).toDouble() : 0.0;
}
