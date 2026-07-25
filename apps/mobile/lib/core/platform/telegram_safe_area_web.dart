import 'dart:js_interop';

import 'telegram_safe_area_base.dart';

/// Web resolution: reads the single resolved inset that web/index.html
/// publishes on window.__tgSafeArea and refreshes on every 'tg-safearea'
/// event. Compiled only for the web target (conditional import).
TelegramSafeArea resolveTelegramSafeArea() => _WebTelegramSafeArea();

@JS('__tgSafeArea')
external _Resolved? get _resolved;

@JS('addEventListener')
external void _addWindowListener(String type, JSFunction callback);

extension type _Resolved(JSObject _) implements JSObject {
  external bool get inTelegram;
  external double get topInset;
  external double get bottom;
  external double get left;
  external double get right;
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
      applyResolved(
        inTelegram: false,
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
      );
      return;
    }
    applyResolved(
      inTelegram: _boolOf(() => raw.inTelegram),
      top: _numOf(() => raw.topInset),
      bottom: _numOf(() => raw.bottom),
      left: _numOf(() => raw.left),
      right: _numOf(() => raw.right),
    );
  }

  _Resolved? _safeRaw() {
    try {
      return _resolved;
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
