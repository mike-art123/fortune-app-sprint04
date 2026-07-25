// Rewarded-ad playback. The web implementation (AdsGram/Monetag SDKs) is
// swapped in only when `dart:js_interop` exists; `flutter test`/`analyze` and
// native targets resolve to the stub, like every platform bridge here.
export 'rewarded_ad_player_stub.dart'
    if (dart.library.js_interop) 'rewarded_ad_player_web.dart';
