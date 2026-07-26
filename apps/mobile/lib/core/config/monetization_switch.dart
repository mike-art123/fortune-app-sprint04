/// Ads and VIP, paused — on purpose, and reversibly.
///
/// Nothing about the access model, the ad mediation chain or the subscription
/// flow has been deleted: the code, its tests and its backend are all intact.
/// While this is false the app simply never asks for any of it, so every
/// fortune opens straight away, no rewarded-ad SDK is ever fetched, and the
/// subscription screen is not offered.
///
/// Two reasons this exists rather than a commented-out block:
///   1. the owner needs to walk the whole app end to end without an ad or a
///      paywall interrupting a single ritual;
///   2. AdsGram's review raised a question, and until it is settled their SDK
///      should not load at all.
///
/// To bring both back, build with:
///   flutter build web --dart-define=ENABLE_MONETIZATION=true
/// and set `ENFORCE_ACCESS_LIMITS=true` on the API. Being a compile-time
/// constant, the paused build also tree-shakes the ad paths away entirely —
/// there is no code path left that could reach a provider SDK.
const bool kMonetizationEnabled = bool.fromEnvironment('ENABLE_MONETIZATION');
