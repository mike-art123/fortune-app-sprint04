// Ambient playback. The web implementation (the browser's own Audio element)
// is swapped in only when `dart:js_interop` exists; `flutter test`/`analyze`
// and native targets resolve to the stub, like every platform bridge here.
export 'ambient_audio_stub.dart'
    if (dart.library.js_interop) 'ambient_audio_web.dart';
