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
  @override
  Future<void> openTelegramLink(String url) async {
    final message = shareMessageFromTelegramLink(url);
    if (message != null) {
      try {
        await SharePlus.instance.share(ShareParams(text: message));
      } catch (_) {
        // A dismissed or failed share sheet is calmer than a crash.
      }
      return;
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
