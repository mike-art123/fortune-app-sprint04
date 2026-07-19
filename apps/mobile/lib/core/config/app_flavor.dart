/// Build flavor (doc 51 §9). Immutable after startup.
enum AppFlavor {
  development,
  staging,
  production;

  bool get isProduction => this == AppFlavor.production;
  bool get isDevelopment => this == AppFlavor.development;
}
