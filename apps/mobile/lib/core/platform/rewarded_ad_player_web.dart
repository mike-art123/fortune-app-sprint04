import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web rewarded-ad adapters (AdsGram, Monetag). Each provider's SDK quirks are
/// contained HERE and mapped to the canonical mediation reasons — fortune
/// screens and the access flow never see provider-specific details.
///
/// Canonical outcomes: `completed`, `skipped`, `no_fill`, `load_timeout`,
/// `ad_unavailable`, `temporary_provider_error`.
Future<String> playRewardedAd({
  required String provider,
  required Map<String, String> config,
  required int timeoutMs,
}) async {
  try {
    final play = switch (provider) {
      'adsgram' => _playAdsgram(config['blockId'] ?? ''),
      'monetag' => _playMonetag(config['zoneId'] ?? ''),
      _ => Future<String>.value('ad_unavailable'),
    };
    return await play.timeout(
      Duration(milliseconds: timeoutMs),
      onTimeout: () => 'load_timeout',
    );
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

// ── AdsGram ────────────────────────────────────────────────────────────────

Future<String> _playAdsgram(String blockId) async {
  if (blockId.isEmpty) return 'ad_unavailable';
  final loaded = await _ensureScript(
    'adsgram-sdk',
    'https://sad.adsgram.ai/js/sad.min.js',
    const {},
  );
  if (!loaded) return 'ad_unavailable';

  final adsgram = globalContext.getProperty<JSObject?>('Adsgram'.toJS);
  if (adsgram == null) return 'ad_unavailable';

  try {
    final init = JSObject()..setProperty('blockId'.toJS, blockId.toJS);
    final controller = adsgram.callMethod<JSObject?>('init'.toJS, init);
    if (controller == null) return 'ad_unavailable';
    final promise = controller.callMethod<JSPromise<JSAny?>?>('show'.toJS);
    if (promise == null) return 'ad_unavailable';
    await promise.toDart;
    // The AdsGram promise resolves only after the ad was watched through.
    return 'completed';
  } catch (error) {
    // Rejection carries {error: bool, done: bool, description}: a user skip
    // rejects with error=false — that must NOT fall through to another
    // provider; a technical error may.
    final isUserSkip = error is JSObject &&
        error.getProperty<JSAny?>('error'.toJS).dartify() == false;
    return isUserSkip ? 'skipped' : 'no_fill';
  }
}

// ── Monetag ────────────────────────────────────────────────────────────────

Future<String> _playMonetag(String zoneId) async {
  if (zoneId.isEmpty) return 'ad_unavailable';
  final fnName = 'show_$zoneId';
  final loaded = await _ensureScript(
    'monetag-sdk-$zoneId',
    'https://libtl.com/sdk.js',
    {'data-zone': zoneId, 'data-sdk': fnName},
  );
  if (!loaded) return 'ad_unavailable';

  // The loader defines window.show_<zone> shortly after the script arrives.
  JSFunction? show;
  for (var attempt = 0; attempt < 20; attempt++) {
    show = globalContext.getProperty<JSFunction?>(fnName.toJS);
    if (show != null) break;
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  if (show == null) return 'ad_unavailable';

  try {
    final result = show.callAsFunction();
    if (result is JSPromise) {
      await (result as JSPromise<JSAny?>).toDart;
    }
    return 'completed';
  } catch (_) {
    // Monetag rejects for no-inventory and user-abort alike; without a
    // distinguishing signal, treat it as no_fill so mediation may continue.
    return 'no_fill';
  }
}
