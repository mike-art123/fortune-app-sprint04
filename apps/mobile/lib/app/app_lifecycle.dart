import 'package:flutter/widgets.dart';

/// Exposes app lifecycle transitions for later use (session refresh, pausing
/// ritual animation, resuming pending purchases) — doc 51 §31.
class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver(this.onStateChanged);
  final void Function(AppLifecycleState state) onStateChanged;

  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      onStateChanged(state);
}
