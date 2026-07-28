// Cup-photo capture for the coffee fortune. The web implementation (a transient
// file input plus a canvas downscale) is swapped in only when `dart:js_interop`
// exists; analyze/test and native targets resolve to the stub, like every
// platform bridge here.
export 'cup_photo_stub.dart' if (dart.library.js_interop) 'cup_photo_web.dart';
