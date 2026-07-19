/// Typed feature flags with safe defaults (doc 51 §29).
/// Source is local immutable config for now; remote sources may be added later
/// without changing call sites.
class FeatureFlags {
  const FeatureFlags({
    this.debugMenuEnabled = false,
    this.analyticsEnabled = false,
    this.crashReportingEnabled = false,
  });

  final bool debugMenuEnabled;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
}
