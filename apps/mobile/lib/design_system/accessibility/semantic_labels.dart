/// Semantic label keys for screen readers. Decorative icons are excluded from
/// semantics; meaningful ones always carry a label (doc 51 §34).
abstract final class SemanticLabels {
  static const back = 'semanticBack';
  static const close = 'semanticClose';
  static const loading = 'semanticLoading';
  static const retry = 'semanticRetry';
}
