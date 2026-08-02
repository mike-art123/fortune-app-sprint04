import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'telegram_platform_bridge.dart';

/// Extracts the share-sheet message from a `t.me/share/url` link, or null
/// when the link is not a share link (callers then open it externally). Kept
/// as a pure function so the routing decision is unit-testable without any
/// plugin channel.
String? shareMessageFromTelegramLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host != 't.me' || uri.path != '/share/url') return null;
  final text = uri.queryParameters['text'];
  final target = uri.queryParameters['url'];
  final message = [
    if (text != null && text.isNotEmpty) text,
    if (target != null && target.isNotEmpty) target,
  ].join('\n');
  return message.isEmpty ? null : message;
}

/// The rectangle the share sheet opens from.
///
/// Documented as an iPad/Mac popover anchor that "has no effect on other
/// devices" — but iOS 26 refuses a zero-sized one outright, and this project
/// is pinned to share_plus 11, below the 12.0.1 release whose changelog reads
/// "Avoid crash on iOS 26 on iPhones with no sharePositionOrigin param". Left
/// unset, the invite button on an iPhone did nothing at all: the plugin threw,
/// and the catch below swallowed it.
///
/// The centre of the screen is a neutral, always-valid anchor, and one logical
/// pixel is enough to be non-zero. Android is unaffected by construction — the
/// parameter has no meaning there.
Rect shareAnchor() {
  const fallback = Rect.fromLTWH(0, 0, 1, 1);
  final view = PlatformDispatcher.instance.implicitView;
  if (view == null) return fallback;
  final width = view.physicalSize.width / view.devicePixelRatio;
  final height = view.physicalSize.height / view.devicePixelRatio;
  // A view reports nothing useful before its first frame, and a zero pixel
  // ratio turns that nothing into NaN — which would sail past a plain `> 0`
  // and hand iOS the very rectangle this function exists to avoid.
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return fallback;
  }
  return Rect.fromCenter(
    center: Offset(width / 2, height / 2),
    width: 1,
    height: 1,
  );
}

/// The Play build's stand-in for the Telegram bridge: links open through the
/// system (url_launcher) and the Telegram share dialog becomes the native
/// Android share sheet. Telegram-only affordances (initData, viewport, the
/// native back button) stay no-ops — Android has its own back gesture, and
/// identity comes from the guest login instead.
///
/// Every action is best-effort: a missing browser or a refused intent must
/// never crash a ritual, so failures degrade to quiet no-ops.
class AndroidPlatformBridge implements TelegramPlatformBridge {
  const AndroidPlatformBridge();

  @override
  bool get isAvailable => false;

  @override
  String? get initData => null;

  @override
  Future<void> expandViewport() async {}

  @override
  Future<void> hapticImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Haptics are a flourish, never a requirement.
    }
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> openLink(String url) => _launchExternal(url);

  /// t.me share links become the native share sheet; every other t.me link
  /// opens externally, which lands in the Telegram app when it is installed.
  ///
  /// A share sheet that refuses to open no longer ends in silence. It falls
  /// through to the same link opened externally, which is Telegram's own share
  /// dialog — so the button always does something, whatever the plugin makes
  /// of this OS version.
  @override
  Future<void> openTelegramLink(String url) async {
    final message = shareMessageFromTelegramLink(url);
    if (message == null) {
      await _launchExternal(url);
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(text: message, sharePositionOrigin: shareAnchor()),
      );
      return;
    } catch (_) {
      // Fall through: somewhere is better than nowhere.
    }
    await _launchExternal(url);
  }

  @override
  Future<void> showBackButton() async {}

  @override
  Future<void> hideBackButton() async {}

  @override
  void setBackButtonHandler(void Function()? handler) {}

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A device with no handler for this link is a no-op, not a failure.
    }
  }
}
