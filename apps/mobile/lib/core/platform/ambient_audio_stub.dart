/// Non-web resolution: ambient sound needs the browser's audio element, so
/// outside a web build nothing plays and nothing fails. Never a crash.
class AmbientAudio {
  /// Deliberately NOT const, even though this stub could be.
  ///
  /// The analyzer only ever sees this file, so a const constructor here makes
  /// `prefer_const_constructors` demand `const AmbientAudio()` at the call
  /// site — which then fails to compile for web, where the real implementation
  /// holds mutable state. Both resolutions have to agree on the constructor,
  /// and the web one cannot be const.
  AmbientAudio();

  bool get isSupported => false;

  Future<void> play(String assetPath, {required double volume}) async {}

  Future<void> stop() async {}

  Future<void> setVolume(double volume) async {}

  Future<void> playOnce(String assetPath, {required double volume}) async {}

  void dispose() {}
}
