// Rewarded-ad playback. Web (`dart:js_interop`) resolves to the
// AdsGram/Monetag adapters; native (`dart:io` — the Play build, and the
// `flutter test` VM with it) resolves to the AdMob player, which answers
// `ad_unavailable` for any provider that is not `admob`, so tests behave
// exactly like the old stub. The stub stays as the formal default.
export 'rewarded_ad_player_stub.dart'
    if (dart.library.js_interop) 'rewarded_ad_player_web.dart'
    if (dart.library.io) 'rewarded_ad_player_io.dart';
