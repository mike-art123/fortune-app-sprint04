import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web resolution: the browser's own `Audio` element (scope §1).
///
/// Compiled ONLY for the web target, via the conditional export in
/// `ambient_audio.dart`. The VM/stub build never loads this file, so
/// `flutter test` and native targets stay silent.
///
/// No package is added for this. An ambient bed is one looping element and a
/// volume ramp; reaching for a plugin would buy nothing and cost a dependency
/// on every platform the app does not ship to.
class AmbientAudio {
  AmbientAudio();

  JSObject? _bed;
  Timer? _fade;

  bool get isSupported =>
      globalContext.getProperty<JSFunction?>('Audio'.toJS) != null;

  JSObject? _element(String assetPath) {
    final audio = globalContext.getProperty<JSFunction?>('Audio'.toJS);
    if (audio == null) return null;
    // Flutter web serves bundled assets from `assets/`, so the manifest path
    // is prefixed once, here, and nowhere else.
    return audio.callAsConstructor<JSObject>('assets/$assetPath'.toJS);
  }

  /// Starts the bed, fading up so nothing ever begins abruptly. Replacing a
  /// bed stops the previous one first: two beds at once is noise, not ambience.
  Future<void> play(String assetPath, {required double volume}) async {
    await stop();
    final element = _element(assetPath);
    if (element == null) return;

    element.setProperty('loop'.toJS, true.toJS);
    element.setProperty('volume'.toJS, 0.toJS);
    _bed = element;

    try {
      element.callMethod<JSAny?>('play'.toJS);
    } catch (_) {
      // Browsers refuse audio until the person has interacted with the page.
      // That refusal is not an error to report — it is the browser being
      // careful on their behalf, and the next tap will succeed.
      _bed = null;
      return;
    }
    _rampTo(volume);
  }

  /// Fades down, then stops. A bed that cuts out is worse than no bed.
  Future<void> stop() async {
    _fade?.cancel();
    _fade = null;
    final element = _bed;
    _bed = null;
    if (element == null) return;

    for (var step = 0; step < _fadeSteps; step++) {
      final left = (_fadeSteps - step - 1) / _fadeSteps;
      element.setProperty('volume'.toJS, (left * _lastVolume).toJS);
      await Future<void>.delayed(_fadeStep);
    }
    element.callMethod<JSAny?>('pause'.toJS);
  }

  Future<void> setVolume(double volume) async {
    _lastVolume = volume.clamp(0, 1).toDouble();
    _bed?.setProperty('volume'.toJS, _lastVolume.toJS);
  }

  /// A one-shot sound that marks a moment. It never loops and never replaces
  /// the bed underneath it.
  Future<void> playOnce(String assetPath, {required double volume}) async {
    final element = _element(assetPath);
    if (element == null) return;
    element.setProperty('volume'.toJS, volume.clamp(0, 1).toDouble().toJS);
    try {
      element.callMethod<JSAny?>('play'.toJS);
    } catch (_) {
      // Same as above: a refusal to autoplay is not a failure worth surfacing.
    }
  }

  void dispose() {
    _fade?.cancel();
    _fade = null;
    _bed?.callMethod<JSAny?>('pause'.toJS);
    _bed = null;
  }

  static const int _fadeSteps = 12;
  static const Duration _fadeStep = Duration(milliseconds: 60);
  double _lastVolume = 0.4;

  void _rampTo(double volume) {
    _lastVolume = volume.clamp(0, 1).toDouble();
    var step = 0;
    _fade?.cancel();
    _fade = Timer.periodic(_fadeStep, (timer) {
      final element = _bed;
      if (element == null) {
        timer.cancel();
        return;
      }
      step++;
      final level = _lastVolume * step / _fadeSteps;
      element.setProperty('volume'.toJS, level.toJS);
      if (step >= _fadeSteps) timer.cancel();
    });
  }
}
