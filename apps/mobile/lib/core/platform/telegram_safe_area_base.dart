import 'package:flutter/foundation.dart';

/// Reactive holder for the resolved Telegram Mini App top inset.
///
/// The heavy lifting — reading safeAreaInset + contentSafeAreaInset, detecting
/// fullscreen, and the iOS fallbacks — happens in web/index.html, which
/// publishes a single already-resolved [topInset]. This just exposes it
/// reactively. Outside Telegram [isTelegram] is false and every inset is 0, so
/// the browser layout is unchanged.
abstract class TelegramSafeArea extends ChangeNotifier {
  double _top = 0;
  double _bottom = 0;
  double _left = 0;
  double _right = 0;
  bool _telegram = false;

  double get topInset => _top;
  double get bottomInset => _bottom;
  double get leftInset => _left;
  double get rightInset => _right;

  /// Whether we're running inside Telegram (its WebApp is present).
  bool get isTelegram => _telegram;

  /// Begin listening to Telegram viewport / safe-area events.
  void start();

  /// Store the values published by index.html and notify on any change.
  void applyResolved({
    required bool inTelegram,
    required double top,
    required double bottom,
    required double left,
    required double right,
  }) {
    final nt = _clamp(top);
    final nb = _clamp(bottom);
    final nl = _clamp(left);
    final nr = _clamp(right);
    final changed = nt != _top ||
        nb != _bottom ||
        nl != _left ||
        nr != _right ||
        inTelegram != _telegram;
    if (!changed) return;

    _top = nt;
    _bottom = nb;
    _left = nl;
    _right = nr;
    _telegram = inTelegram;

    if (kDebugMode) {
      debugPrint('[tg-safearea] inTelegram=$inTelegram topInset=$_top');
    }
    notifyListeners();
  }

  static double _clamp(double value) =>
      value.isFinite ? value.clamp(0.0, 200.0).toDouble() : 0.0;
}
