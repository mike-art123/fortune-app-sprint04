import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web resolution: open the native camera/gallery through a transient
/// `<input type="file" accept="image/*" capture="environment">`, then downscale
/// the chosen photo to a compact JPEG data URL on a canvas.
///
/// Compiled ONLY for the web target, via the conditional export in
/// `cup_photo.dart`. The VM/stub build never loads this file, so `flutter test`
/// and native targets return null ("no camera here").
///
/// The full-size photo never leaves the device: only the downscaled data URL
/// is returned, and the server reads it once and never stores it (privacy §16).
const int _maxDimension = 1080;
const double _jpegQuality = 0.82;

/// Keeps the active picker alive across the camera round-trip. iOS WebKit
/// (Telegram's WKWebView included) suspends the page while the camera is up;
/// a detached, unreferenced input can be collected in that gap and `change`
/// then never fires — the photo silently vanishes.
JSObject? _activeInput;

Future<String?> captureCupPhoto() {
  final document = globalContext.getProperty<JSObject?>('document'.toJS);
  if (document == null) return Future<String?>.value(null);

  final completer = Completer<String?>();
  var settled = false;

  final input = document.callMethod<JSObject>(
    'createElement'.toJS,
    'input'.toJS,
  );

  void finish(String? value) {
    if (settled) return;
    settled = true;
    try {
      input.callMethod<JSAny?>('remove'.toJS);
    } catch (_) {
      // Detachment is cosmetic; never let cleanup eat the result.
    }
    if (identical(_activeInput, input)) _activeInput = null;
    if (!completer.isCompleted) completer.complete(value);
  }

  // A previous picker that never resolved (old WebKit fires no `cancel`)
  // must not linger once a new capture starts.
  try {
    _activeInput?.callMethod<JSAny?>('remove'.toJS);
  } catch (_) {
    // Same: cleanup is best effort.
  }

  input.setProperty('type'.toJS, 'file'.toJS);
  input.setProperty('accept'.toJS, 'image/*'.toJS);
  input.setProperty('capture'.toJS, 'environment'.toJS);

  // iOS only delivers the captured file reliably when the input is attached
  // to the document and survives the camera round-trip.
  final style = input.getProperty<JSObject?>('style'.toJS);
  style?.setProperty('display'.toJS, 'none'.toJS);
  final body = document.getProperty<JSObject?>('body'.toJS);
  body?.callMethod<JSAny?>('appendChild'.toJS, input);
  _activeInput = input;

  input.setProperty(
    'onchange'.toJS,
    (() {
      final files = input.getProperty<JSObject?>('files'.toJS);
      final length = files?.getProperty<JSNumber?>('length'.toJS);
      final count = length?.toDartInt ?? 0;
      if (files == null || count == 0) {
        finish(null);
        return;
      }
      final file = files.callMethod<JSObject?>('item'.toJS, 0.toJS);
      if (file == null) {
        finish(null);
        return;
      }
      _downscale(document, file, finish);
    }).toJS,
  );

  // Newer WebKit fires `cancel` when the sheet is dismissed; without it the
  // button would look dead until the next tap.
  input.setProperty('oncancel'.toJS, (() => finish(null)).toJS);

  input.callMethod<JSAny?>('click'.toJS);
  return completer.future;
}

void _downscale(
  JSObject document,
  JSObject file,
  void Function(String?) finish,
) {
  final url = globalContext.getProperty<JSObject?>('URL'.toJS);
  final imageCtor = globalContext.getProperty<JSFunction?>('Image'.toJS);
  final objectUrl = url?.callMethod<JSString?>('createObjectURL'.toJS, file);
  if (url == null || imageCtor == null || objectUrl == null) {
    _readRaw(file, finish);
    return;
  }

  final image = imageCtor.callAsConstructor<JSObject>();

  void revoke() {
    try {
      url.callMethod<JSAny?>('revokeObjectURL'.toJS, objectUrl);
    } catch (_) {
      // Best effort; the browser reclaims it on unload regardless.
    }
  }

  image.setProperty(
    'onload'.toJS,
    (() {
      final data = _encode(document, image);
      revoke();
      if (data != null) {
        finish(data);
      } else {
        // Canvas refused this image (rare codecs) — the raw file still works.
        _readRaw(file, finish);
      }
    }).toJS,
  );
  image.setProperty(
    'onerror'.toJS,
    (() {
      revoke();
      finish(null);
    }).toJS,
  );
  image.setProperty('src'.toJS, objectUrl);
}

/// Draws the loaded image onto a downscaled canvas and returns a JPEG data
/// URL, or null if the browser cannot encode it.
String? _encode(JSObject document, JSObject image) {
  try {
    final natW = image.getProperty<JSNumber?>('naturalWidth'.toJS)?.toDartInt;
    final natH = image.getProperty<JSNumber?>('naturalHeight'.toJS)?.toDartInt;
    if (natW == null || natH == null || natW == 0 || natH == 0) return null;

    final longest = natW > natH ? natW : natH;
    final scale = longest > _maxDimension ? _maxDimension / longest : 1.0;
    final w = (natW * scale).round();
    final h = (natH * scale).round();

    final canvas = document.callMethod<JSObject>(
      'createElement'.toJS,
      'canvas'.toJS,
    );
    canvas.setProperty('width'.toJS, w.toJS);
    canvas.setProperty('height'.toJS, h.toJS);
    final ctx = canvas.callMethod<JSObject?>('getContext'.toJS, '2d'.toJS);
    if (ctx == null) return null;

    ctx.callMethod<JSAny?>('scale'.toJS, scale.toJS, scale.toJS);
    ctx.callMethod<JSAny?>('drawImage'.toJS, image, 0.toJS, 0.toJS);
    final data = canvas.callMethod<JSString?>(
      'toDataURL'.toJS,
      'image/jpeg'.toJS,
      _jpegQuality.toJS,
    );
    return data?.toDart;
  } catch (_) {
    return null;
  }
}

void _readRaw(JSObject file, void Function(String?) finish) {
  final ctor = globalContext.getProperty<JSFunction?>('FileReader'.toJS);
  if (ctor == null) {
    finish(null);
    return;
  }
  final reader = ctor.callAsConstructor<JSObject>();
  reader.setProperty(
    'onload'.toJS,
    (() {
      finish(reader.getProperty<JSString?>('result'.toJS)?.toDart);
    }).toJS,
  );
  reader.setProperty('onerror'.toJS, (() => finish(null)).toJS);
  reader.callMethod<JSAny?>('readAsDataURL'.toJS, file);
}
