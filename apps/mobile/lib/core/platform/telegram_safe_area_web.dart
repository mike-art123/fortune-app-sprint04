import 'dart:js_interop';

import 'telegram_safe_area_base.dart';

/// Web resolution: reads the safe-area globals that `web/index.html` publishes
/// from Telegram.WebApp, and refreshes on every Telegram safe-area / viewport /
/// fullscreen event. Compiled only for the web target (conditional import).
TelegramSafeArea resolveTelegramSafeArea() => _WebTelegramSafeArea();

@JS('__tgSafeArea')
external _RawInsets? get _rawInsets;

@JS('addEventListener')
external void _addWindowListener(String type, JSFunction callback);

extension type _RawInsets(JSObject _) implements JSObject {
  external double get top;
  external double get bottom;
  external double get left;
  external double get right;
  external double get contentTop;
  external bool get fullscreen;
}

class _WebTelegramSafeArea extends TelegramSafeArea {
  @override
  void start() {
    _addWindowListener('tg-safearea', _onChange.toJS);
    _read();
  }

  void _onChange(JSAny _) => _read();

  void _read() {
    final raw = _safeRaw();
    if (raw == null) {
      applyInsets(
        available: false,
        fullscreen: false,
        safeTop: 0,
        safeBottom: 0,
        safeLeft: 0,
        safeRight: 0,
        contentTop: 0,
      );
      return;
    }
    applyInsets(
      available: true,
      fullscreen: _boolOf(() => raw.fullscreen),
      safeTop: _numOf(() => raw.top),
      safeBottom: _numOf(() => raw.bottom),
      safeLeft: _numOf(() => raw.left),
      safeRight: _numOf(() => raw.right),
      contentTop: _numOf(() => raw.contentTop),
    );
  }

  _RawInsets? _safeRaw() {
    try {
      return _rawInsets;
    } catch (_) {
      return null;
    }
  }

  double _numOf(double Function() read) {
    try {
      final v = read();
      return v.isFinite ? v : 0;
    } catch (_) {
      return 0;
    }
  }

  bool _boolOf(bool Function() read) {
    try {
      return read();
    } catch (_) {
      return false;
    }
  }
}
