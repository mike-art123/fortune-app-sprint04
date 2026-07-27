import 'package:flutter/material.dart';

import 'telegram_safe_area.dart';

/// Top padding that clears Telegram's own control row (Close · ⌄ · …), which
/// floats above the mini app rather than pushing it down. Any full-screen
/// destination that puts something at the very top needs this — the fortunes
/// page did not have it, so its search field sat underneath the Close button
/// and could not be tapped at all.
///
/// Lifted out of HomePage so the two cannot drift: one page quietly disagreeing
/// with the other about where the top of the screen is was the whole bug.
double telegramTopInset(BuildContext context) {
  final viewTop = MediaQuery.viewPaddingOf(context).top;
  final safeArea = telegramSafeArea;
  if (safeArea.isTelegram) {
    final top = safeArea.topInset;
    if (top > 0.5) return top;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final device = viewTop > 0 ? viewTop : (isIOS ? 59.0 : 24.0);
    return (device + (isIOS ? 44.0 : 12.0)).clamp(0.0, 200.0).toDouble();
  }
  return viewTop > 8 ? viewTop : 8.0;
}
