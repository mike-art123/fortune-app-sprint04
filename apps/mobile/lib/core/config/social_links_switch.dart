/// The three doors out of the app: «دعوت از دوستان», the Telegram channel and
/// the Instagram page.
///
/// They break no App Store rule. Guideline 3.1.1 restricts links that lead to
/// a way of paying outside the app, and nothing in this app is for sale on any
/// platform; Telegram and Instagram are services, not the "other mobile
/// platforms or alternative app marketplaces" guideline 2.3.10 is about. The
/// research is in `claude/ios-appstore-compliance.md` and it came out clean.
///
/// They are off for the first iOS submission anyway. A fortune-telling app is
/// named in guideline 4.3(b) as a category Apple will not accept "unless
/// [it] offer[s] a meaningfully different or improved experience", so the
/// first review is the one that matters, and the cleanest thing to hand a
/// reviewer is an app with nothing to buy, no account, and nowhere it sends
/// them. Every one of these can come back in 1.1 by dropping the define.
///
/// Compile-time, so an iOS build carries no channel address at all rather
/// than merely hiding the buttons. Default true: ci.yml and deploy-pages.yml
/// pass nothing, so the web bundle and the Play build keep all three exactly
/// as they are today.
const bool kSocialLinksEnabled = bool.fromEnvironment(
  'ENABLE_SOCIAL_LINKS',
  defaultValue: true,
);
