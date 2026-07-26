// Speech recognition. The web implementation (Web Speech API) is swapped in
// only when `dart:js_interop` exists; `flutter test`/`analyze` and native
// targets resolve to the stub, like every platform bridge here.
export 'speech_recognition_stub.dart'
    if (dart.library.js_interop) 'speech_recognition_web.dart';
