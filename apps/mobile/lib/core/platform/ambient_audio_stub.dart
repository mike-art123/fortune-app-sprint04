/// Non-web resolution: ambient sound needs the browser's audio element, so
/// outside a web build nothing plays and nothing fails. Never a crash.
class AmbientAudio {
  const AmbientAudio();

  bool get isSupported => false;

  Future<void> play(String assetPath, {required double volume}) async {}

  Future<void> stop() async {}

  Future<void> setVolume(double volume) async {}

  Future<void> playOnce(String assetPath, {required double volume}) async {}

  void dispose() {}
}
