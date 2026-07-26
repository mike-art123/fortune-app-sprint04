import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/persistence/local_storage.dart';
import 'package:fortune_app/core/platform/ambient_audio.dart';
import 'package:fortune_app/features/audio/application/audio_controller.dart';
import 'package:fortune_app/features/audio/data/audio_preferences_repository.dart';
import 'package:fortune_app/features/audio/domain/audio_theme.dart';
import 'package:fortune_app/shared/providers/shared_providers.dart';

/// Records what was asked of the speakers, so silence can be asserted.
class SpyAudio implements AmbientAudio {
  final List<String> played = [];
  final List<String> once = [];
  int stops = 0;
  double? volume;

  @override
  bool get isSupported => true;

  @override
  Future<void> play(String assetPath, {required double volume}) async {
    played.add(assetPath);
    this.volume = volume;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> playOnce(String assetPath, {required double volume}) async =>
      once.add(assetPath);

  @override
  void dispose() {}
}

ProviderContainer container(SpyAudio audio, {LocalStorage? storage}) {
  final c = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage ?? InMemoryStorage()),
      ambientAudioProvider.overrideWithValue(audio),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Sound is the one feature that can embarrass somebody in a quiet room, so
/// every test here is about it staying off until it is asked for — and about
/// the app never offering a bed nobody licensed.
void main() {
  // AudioController watches the app's lifecycle, which needs a binding even in
  // a plain ProviderContainer test.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the shipped build offers no bed until the files exist', () {
    // A deliberate tripwire: when the licensed audio lands, this test fails and
    // points at everything below that must be revisited.
    expect(AudioThemes.bundled, isEmpty);
    expect(AudioThemes.available, isEmpty);
    expect(AudioThemes.hasAny, isFalse);
  });

  test('`bundled` and pubspec are the same fact, so they cannot drift', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(r'^\s*-\s*(assets/audio/\S+)$', multiLine: true)
        .allMatches(pubspec)
        .map((m) => m.group(1)!)
        .toSet();

    // Every bundled path must be declared, and every declared audio asset must
    // be bundled. When the owner adds a file, exactly one of these fails and
    // says which list is behind.
    expect(AudioThemes.bundled.difference(declared), isEmpty);
    for (final path in declared) {
      expect(
        AudioThemes.bundled.any((bundled) => bundled.startsWith(path)),
        isTrue,
        reason: '$path is declared but no bundled path starts with it',
      );
    }
  });

  test('every theme has a Persian name and one predictable path', () {
    expect(AudioTheme.values, hasLength(7));
    for (final theme in AudioTheme.values) {
      expect(theme.labelFa, isNotEmpty);
      expect(theme.assetPath, 'assets/audio/ambient/${theme.id}.mp3');
      expect(audioThemeFromId(theme.id), theme);
    }
    expect(audioThemeFromId('gramophone'), isNull);
    expect(audioThemeFromId(null), isNull);
  });

  test('silence is the default, and a stored choice is honoured', () async {
    final empty = AudioPreferencesRepository(InMemoryStorage());
    final fresh = empty.read();
    expect(fresh.enabled, isFalse);
    expect(fresh.volume, AudioPreferencesRepository.defaultVolume);

    final storage = InMemoryStorage();
    final repo = AudioPreferencesRepository(storage);
    await repo.save(
      const AudioState(enabled: true, theme: AudioTheme.rain, volume: 0.75),
    );

    final read = repo.read();
    expect(read.enabled, isTrue);
    expect(read.theme, AudioTheme.rain);
    expect(read.volume, closeTo(0.75, 0.001));
  });

  test('nothing plays while there is no licensed bed to play', () async {
    final audio = SpyAudio();
    final c = container(audio);
    final controller = c.read(audioControllerProvider.notifier);

    await controller.setEnabled(true);
    await controller.chooseTheme(AudioTheme.night);

    // Asked for, agreed to — and still silent, because the file is not there.
    expect(c.read(audioControllerProvider).enabled, isTrue);
    expect(c.read(audioControllerProvider).shouldPlay, isFalse);
    expect(audio.played, isEmpty);
  });

  test('a ritual sound stays silent unless sound is on and licensed', () async {
    final audio = SpyAudio();
    final c = container(audio);
    final controller = c.read(audioControllerProvider.notifier);

    await controller.playRitual(RitualSound.reveal);
    await controller.setEnabled(true);
    await controller.playRitual(RitualSound.reveal);

    expect(audio.once, isEmpty);
  });

  test('turning sound off stops whatever was sounding', () async {
    final audio = SpyAudio();
    final c = container(audio);
    final controller = c.read(audioControllerProvider.notifier);

    await controller.setEnabled(false);
    expect(audio.stops, greaterThan(0));
    expect(audio.played, isEmpty);
  });

  test('volume is remembered and passed straight through', () async {
    final storage = InMemoryStorage();
    final audio = SpyAudio();
    final c = container(audio, storage: storage);

    await c.read(audioControllerProvider.notifier).setVolume(0.9);

    expect(audio.volume, closeTo(0.9, 0.001));
    final stored = AudioPreferencesRepository(storage).read();
    expect(stored.volume, closeTo(0.9, 0.01));
  });
}
