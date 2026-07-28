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

Future<String?> captureCupPhoto() {
  final document = globalContext.getProperty<JSObject?>('document'.toJS);
  if (document == null) return Future<String?>.value(null);

  final completer = Completer<String?>();
  var settled = false;
  void finish(String? value) {
    if (settled) return;
    settled = true;
    if (!completer.isCompleted) completer.complete(value);
  }

  final input = document.callMethod<JSObject>(
    'createElement'.toJS,
    'input'.toJS,
  );
  input.setProperty('type'.toJS, 'file'.toJS);
  input.setProperty('accept'.toJS, 'image/*'.toJS);
  input.setProperty('capture'.toJS, 'environment'.toJS);

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
      finish(data);
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
