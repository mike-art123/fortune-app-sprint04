// Startup warm-up for the ad SDK. Web resolves to the no-op stub — the
// AdsGram/Monetag adapters load lazily inside the web player — and on the
// native side the paused build folds `kMonetizationEnabled == false` at
// compile time, so no ad SDK code is reached until monetization is on.
export 'ads_bootstrap_stub.dart' if (dart.library.io) 'ads_bootstrap_io.dart';
