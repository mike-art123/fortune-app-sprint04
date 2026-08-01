import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web resolution: open the camera or the photo library, then downscale the
/// chosen photo to a compact JPEG data URL on a canvas.
///
/// Two capture paths, picked per platform:
///
/// * **Android (Telegram's WebView):** the chooser behind
///   `<input type="file">` ignores the `capture` attribute and jumps straight
///   to the gallery, so the camera runs *inside the page* — `getUserMedia`
///   with a minimal live-preview overlay (video, shutter, close). When the
///   camera cannot start (denied, absent), the input picker is the fallback.
/// * **iOS and everything else:** the transient
///   `<input type="file" accept="image/*" capture="environment">`, which iOS
///   resolves natively to the camera.
///
/// Compiled ONLY for the web target, via the conditional export in
/// `cup_photo.dart`. The VM/stub build never loads this file, so `flutter
/// test` and native targets return null ("no camera here").
///
/// The full-size photo never leaves the device: only the downscaled data URL
/// is returned, and the server reads it once and never stores it (privacy
/// §16).
const int _maxDimension = 1080;
const double _jpegQuality = 0.82;

/// Keeps the active picker alive across the camera round-trip. iOS WebKit
/// (Telegram's WKWebView included) suspends the page while the camera is up;
/// a detached, unreferenced input can be collected in that gap and `change`
/// then never fires — the photo silently vanishes.
JSObject? _activeInput;

/// Dismisses a live-camera overlay that a navigation left behind, so a stale
/// preview can never sit on top of a new capture.
void Function()? _dismissLiveCamera;

/// Outcome of the in-page camera: `handled` means the overlay ran and the
/// user decided (photo or close) — no fallback picker should follow.
typedef _LiveResult = ({bool handled, String? data});

Future<String?> captureCupPhoto() async {
  final document = globalContext.getProperty<JSObject?>('document'.toJS);
  if (document == null) return null;
  if (_isAndroid) {
    final live = await _captureViaLiveCamera(document);
    if (live.handled) return live.data;
  }
  return _pickViaInput(document, capture: true);
}

/// Opens the photo library / file picker without engaging the camera.
Future<String?> pickCupPhotoFromGallery() {
  final document = globalContext.getProperty<JSObject?>('document'.toJS);
  if (document == null) return Future<String?>.value(null);
  return _pickViaInput(document, capture: false);
}

bool get _isAndroid {
  final navigator = globalContext.getProperty<JSObject?>('navigator'.toJS);
  final agent = navigator?.getProperty<JSString?>('userAgent'.toJS)?.toDart;
  return (agent ?? '').contains('Android');
}

/// Live in-page camera: a full-screen preview with a shutter and a close
/// button, drawn with plain DOM so it needs no Flutter plumbing. Runs where
/// the file input cannot reach the camera (Android Telegram).
Future<_LiveResult> _captureViaLiveCamera(JSObject document) async {
  final navigator = globalContext.getProperty<JSObject?>('navigator'.toJS);
  final devices = navigator?.getProperty<JSObject?>('mediaDevices'.toJS);
  final body = document.getProperty<JSObject?>('body'.toJS);
  if (devices == null || body == null) return (handled: false, data: null);

  JSObject stream;
  try {
    final videoConstraint = JSObject();
    videoConstraint.setProperty('facingMode'.toJS, 'environment'.toJS);
    final constraints = JSObject();
    constraints.setProperty('video'.toJS, videoConstraint);
    constraints.setProperty('audio'.toJS, false.toJS);
    final request = devices.callMethod<JSPromise<JSObject>>(
      'getUserMedia'.toJS,
      constraints,
    );
    stream = await request.toDart;
  } catch (_) {
    // Denied or no usable camera — the input picker takes over.
    return (handled: false, data: null);
  }

  final overlay = document.callMethod<JSObject>(
    'createElement'.toJS,
    'div'.toJS,
  );
  _setStyle(
    overlay,
    'position:fixed;inset:0;z-index:2147483000;background:#000;',
  );

  final video = document.callMethod<JSObject>(
    'createElement'.toJS,
    'video'.toJS,
  );
  video.callMethod<JSAny?>('setAttribute'.toJS, 'playsinline'.toJS, ''.toJS);
  video.setProperty('muted'.toJS, true.toJS);
  video.setProperty('autoplay'.toJS, true.toJS);
  _setStyle(
    video,
    'position:absolute;inset:0;width:100%;height:100%;object-fit:cover;',
  );

  final shutter = document.callMethod<JSObject>(
    'createElement'.toJS,
    'button'.toJS,
  );
  _setStyle(
    shutter,
    'position:absolute;bottom:36px;left:50%;transform:translateX(-50%);'
    'width:72px;height:72px;border-radius:50%;background:#fff;'
    'border:5px solid rgba(255,255,255,0.4);padding:0;',
  );

  final close = document.callMethod<JSObject>(
    'createElement'.toJS,
    'button'.toJS,
  );
  close.setProperty('textContent'.toJS, '✕'.toJS);
  _setStyle(
    close,
    'position:absolute;top:16px;right:16px;width:44px;height:44px;'
    'border-radius:50%;background:rgba(0,0,0,0.55);color:#fff;border:none;'
    'font-size:20px;padding:0;',
  );

  overlay.callMethod<JSAny?>('appendChild'.toJS, video);
  overlay.callMethod<JSAny?>('appendChild'.toJS, shutter);
  overlay.callMethod<JSAny?>('appendChild'.toJS, close);
  body.callMethod<JSAny?>('appendChild'.toJS, overlay);

  final completer = Completer<_LiveResult>();
  var settled = false;
  void Function()? dismiss;

  void finish(_LiveResult result) {
    if (settled) return;
    settled = true;
    _stopTracks(stream);
    try {
      overlay.callMethod<JSAny?>('remove'.toJS);
    } catch (_) {
      // Detachment is cosmetic; never let cleanup eat the result.
    }
    if (identical(_dismissLiveCamera, dismiss)) _dismissLiveCamera = null;
    if (!completer.isCompleted) completer.complete(result);
  }

  dismiss = () => finish((handled: true, data: null));
  _dismissLiveCamera?.call();
  _dismissLiveCamera = dismiss;

  shutter.setProperty(
    'onclick'.toJS,
    (() {
      // A tap before the first frame arrives just waits for the preview.
      final frame = _encodeVideoFrame(document, video);
      if (frame == null) return;
      finish((handled: true, data: frame));
    }).toJS,
  );
  close.setProperty(
    'onclick'.toJS,
    (() => finish((handled: true, data: null))).toJS,
  );

  video.setProperty('srcObject'.toJS, stream);
  video.callMethod<JSAny?>('play'.toJS);
  return completer.future;
}

void _setStyle(JSObject element, String css) {
  final style = element.getProperty<JSObject?>('style'.toJS);
  style?.setProperty('cssText'.toJS, css.toJS);
}

void _stopTracks(JSObject stream) {
  try {
    final tracks = stream.callMethod<JSObject?>('getTracks'.toJS);
    final length = tracks?.getProperty<JSNumber?>('length'.toJS);
    final count = length?.toDartInt ?? 0;
    for (var i = 0; i < count; i++) {
      tracks?.getProperty<JSObject?>(i.toJS)?.callMethod<JSAny?>('stop'.toJS);
    }
  } catch (_) {
    // The browser releases the camera on unload regardless.
  }
}

/// Grabs the current video frame and downscales it to the JPEG budget.
String? _encodeVideoFrame(JSObject document, JSObject video) {
  final w = video.getProperty<JSNumber?>('videoWidth'.toJS)?.toDartInt ?? 0;
  final h = video.getProperty<JSNumber?>('videoHeight'.toJS)?.toDartInt ?? 0;
  if (w == 0 || h == 0) return null;
  return _encodeOnCanvas(document, video, w, h);
}

Future<String?> _pickViaInput(JSObject document, {required bool capture}) {
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
  if (capture) {
    // The content attribute (not the JS property) is what engines read.
    input.callMethod<JSAny?>(
      'setAttribute'.toJS,
      'capture'.toJS,
      'environment'.toJS,
    );
  }

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
  final natW = image.getProperty<JSNumber?>('naturalWidth'.toJS)?.toDartInt;
  final natH = image.getProperty<JSNumber?>('naturalHeight'.toJS)?.toDartInt;
  if (natW == null || natH == null || natW == 0 || natH == 0) return null;
  return _encodeOnCanvas(document, image, natW, natH);
}

/// Downscales any drawable source (image, video frame) to the JPEG budget.
String? _encodeOnCanvas(JSObject document, JSObject source, int w, int h) {
  try {
    final longest = w > h ? w : h;
    final scale = longest > _maxDimension ? _maxDimension / longest : 1.0;
    final outW = (w * scale).round();
    final outH = (h * scale).round();

    final canvas = document.callMethod<JSObject>(
      'createElement'.toJS,
      'canvas'.toJS,
    );
    canvas.setProperty('width'.toJS, outW.toJS);
    canvas.setProperty('height'.toJS, outH.toJS);
    final ctx = canvas.callMethod<JSObject?>('getContext'.toJS, '2d'.toJS);
    if (ctx == null) return null;

    ctx.callMethod<JSAny?>('scale'.toJS, scale.toJS, scale.toJS);
    ctx.callMethod<JSAny?>('drawImage'.toJS, source, 0.toJS, 0.toJS);
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
