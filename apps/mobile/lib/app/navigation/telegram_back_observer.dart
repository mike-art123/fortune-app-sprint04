import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../core/platform/telegram_platform_bridge.dart';
import 'app_back.dart';

/// Keeps the Telegram Mini App native BackButton in sync with the route stack:
/// shown only where a back is meaningful, hidden on the stack roots (Home /
/// Explore), and always wired — through a SINGLE handler — to the same
/// [AppBack] logic as the in-app back button, so the two never disagree.
///
/// Off Telegram the bridge is a no-op, so this observer is harmless everywhere
/// else. It registers one handler at a time; [dispose] clears it and hides the
/// button so no stale listener survives.
class TelegramBackObserver extends NavigatorObserver {
  TelegramBackObserver(this._bridge);

  final TelegramPlatformBridge _bridge;
  GoRouter? _router;

  /// Bound once, right after the router is built (the router can't exist before
  /// its own observers do).
  void bind(GoRouter router) {
    _router = router;
    _sync();
  }

  void dispose() {
    _bridge.setBackButtonHandler(null);
    _bridge.hideBackButton();
  }

  void _sync() {
    final router = _router;
    if (router == null) return;
    final location = router.routerDelegate.currentConfiguration.uri.path;
    final show = AppBack.showBack(
      location: location,
      canPop: router.canPop(),
    );
    if (show) {
      _bridge.setBackButtonHandler(() => AppBack.goBackWith(router));
      _bridge.showBackButton();
    } else {
      _bridge.setBackButtonHandler(null);
      _bridge.hideBackButton();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _sync();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _sync();
}
