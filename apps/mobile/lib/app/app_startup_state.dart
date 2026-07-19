/// Explicit startup lifecycle (doc 51 §4.3 / §42). No boolean soup.
sealed class AppStartupState {
  const AppStartupState();
}

class StartupInProgress extends AppStartupState {
  const StartupInProgress();
}

class StartupReady extends AppStartupState {
  const StartupReady();
}

class StartupFailed extends AppStartupState {
  const StartupFailed(this.reason);
  final String reason;
}
