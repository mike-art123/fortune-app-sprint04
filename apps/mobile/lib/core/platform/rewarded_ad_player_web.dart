import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web rewarded-ad adapters (AdsGram, Monetag). Each provider's SDK quirks are
/// contained HERE and mapped to the canonical mediation reasons — fortune
/// screens and the access flow never see provider-specific details.
///
/// Canonical outcomes: `completed`, `skipped`, `no_fill`, `load_timeout`,
/// `ad_unavailable`, `temporary_provider_error`.
///
/// Timing model: [timeoutMs] (the server's AD_LOAD_TIMEOUT_MS) budgets the
/// LOAD phase only — fetching the SDK and getting an ad ready to show. The
/// WATCH phase is open-ended by design: Monetag's rewarded flow ends with a
/// user tap, so cutting it with the load budget threw away real rewards
/// (the ad outlived 12s, the app called it a timeout, and the resolution
/// arrived with nobody listening). [_watchCap] only guards abandonment.
const _watchCap = Duration(minutes: 4);

Future<String> playRewardedAd({
  required String provider,
  required Map<String, String> config,
  required int timeoutMs,
}) async {
  try {
    return switch (provider) {
      'adsgram' => await _playAdsgram(config['blockId'] ?? '', timeoutMs),
      'monetag' => await _playMonetag(config['zoneId'] ?? '', timeoutMs),
      _ => 'ad_unavailable',
    };
  } catch (_) {
    return 'temporary_provider_error';
  }
}

// ── DOM helpers ────────────────────────────────────────────────────────────

@JS('document')
external JSObject get _document;

/// Injects a script once (keyed by id) and resolves when it loads.
Future<bool> _ensureScript(
  String id,
  String src,
  Map<String, String> attributes,
) {
  final existing = _document.callMethod<JSAny?>(
    'getElementById'.toJS,
    id.toJS,
  );
  if (existing != null) return Future.value(true);

  final completer = Completer<bool>();
  final script = _document.callMethod<JSObject>(
    'createElement'.toJS,
    'script'.toJS,
  );
  script.setProperty('id'.toJS, id.toJS);
  script.setProperty('src'.toJS, src.toJS);
  script.setProperty('async'.toJS, true.toJS);
  for (final entry in attributes.entries) {
    script.callMethod<JSAny?>(
      'setAttribute'.toJS,
      entry.key.toJS,
      entry.value.toJS,
    );
  }
  void finish(bool ok) {
    if (!completer.isCompleted) completer.complete(ok);
  }

  script.setProperty('onload'.toJS, (() => finish(true)).toJS);
  script.setProperty('onerror'.toJS, ((JSAny? _) => finish(false)).toJS);
  final head = _document.getProperty<JSObject?>('head'.toJS);
  head?.callMethod<JSAny?>('appendChild'.toJS, script);
  return completer.future;
}

/// Awaits the provider's show() promise — the watch phase. Distinguishes the
/// three endings every SDK shares: settled fine, rejected, or left hanging.
Future<String> _watch(
  JSPromise<JSAny?> promise, {
  required String onReject,
}) async {
  try {
    await promise.toDart.timeout(_watchCap);
    return 'completed';
  } on TimeoutException {
    // Open this long means abandoned, not unfilled. Never falls through to
    // another provider — a second ad must not appear over a hung first one.
    return 'skipped';
  } catch (_) {
    return onReject;
  }
}

// ── AdsGram ────────────────────────────────────────────────────────────────

Future<String> _playAdsgram(String blockId, int loadTimeoutMs) async {
  if (blockId.isEmpty) return 'ad_unavailable';

  // Load = script + global only. show() must stay OUT of the timed phase: a
  // future abandoned by timeout keeps running, and a show() inside it would
  // pop a ghost ad later with nobody listening for the reward.
  Future<bool> load() async {
    final loaded = await _ensureScript(
      'adsgram-sdk',
      'https://sad.adsgram.ai/js/sad.min.js',
      const {},
    );
    if (!loaded) return false;
    return globalContext.hasProperty('Adsgram'.toJS).toDart;
  }

  bool ready;
  try {
    ready = await load().timeout(Duration(milliseconds: loadTimeoutMs));
  } on TimeoutException {
    return 'load_timeout';
  }
  if (!ready) return 'ad_unavailable';

  final adsgram = globalContext.getProperty<JSObject?>('Adsgram'.toJS);
  if (adsgram == null) return 'ad_unavailable';
  final init = JSObject()..setProperty('blockId'.toJS, blockId.toJS);
  final controller = adsgram.callMethod<JSObject?>('init'.toJS, init);
  if (controller == null) return 'ad_unavailable';
  final promise = controller.callMethod<JSPromise<JSAny?>?>('show'.toJS);
  if (promise == null) return 'ad_unavailable';

  // AdsGram rejects for both user skips and no-fill. Distinguishing them
  // needs a JS-type runtime check that is not platform-consistent (analyzer:
  // invalid_runtime_check_with_js_interop_types), so we take the safe side:
  // treat every rejection as a user stop. Mediation never double-shows an
  // ad this way; refining the mapping comes with live block-id testing.
  return _watch(promise, onReject: 'skipped');
}

// ── Monetag ────────────────────────────────────────────────────────────────

Future<String> _playMonetag(String zoneId, int loadTimeoutMs) async {
  if (zoneId.isEmpty) return 'ad_unavailable';
  final fnName = 'show_$zoneId';

  Future<bool> load() async {
    final loaded = await _ensureScript(
      'monetag-sdk-$zoneId',
      'https://libtl.com/sdk.js',
      {'data-zone': zoneId, 'data-sdk': fnName},
    );
    if (!loaded) return false;
    // The loader defines window.show_<zone> shortly after the script arrives.
    for (var attempt = 0; attempt < 20; attempt++) {
      if (globalContext.hasProperty(fnName.toJS).toDart) return true;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return false;
  }

  bool ready;
  try {
    ready = await load().timeout(Duration(milliseconds: loadTimeoutMs));
  } on TimeoutException {
    return 'load_timeout';
  }
  if (!ready) return 'ad_unavailable';

  // Typed through the interop generic — no JS-type is/as runtime checks.
  final promise = globalContext.callMethod<JSPromise<JSAny?>?>(fnName.toJS);
  if (promise == null) return 'ad_unavailable';

  // Monetag rejects for no-inventory and user-abort alike; without a
  // distinguishing signal, treat it as no_fill so mediation may continue.
  return _watch(promise, onReject: 'no_fill');
}
