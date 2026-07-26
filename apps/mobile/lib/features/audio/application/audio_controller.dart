import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/ambient_audio.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/audio_preferences_repository.dart';
import '../domain/audio_theme.dart';

final ambientAudioProvider = Provider<AmbientAudio>((ref) {
  final player = AmbientAudio();
  ref.onDispose(player.dispose);
  return player;
});

final audioPreferencesRepositoryProvider = Provider<AudioPreferencesRepository>(
  (ref) => AudioPreferencesRepository(ref.watch(localStorageProvider)),
);

/// What the app is playing, and what this person asked for (scope §1).
class AudioState {
  const AudioState({
    required this.enabled,
    required this.theme,
    required this.volume,
  });

  final bool enabled;
  final AudioTheme? theme;
  final double volume;

  /// Whether a bed should be sounding right now. A theme nobody licensed can
  /// never satisfy this, however the switches are set.
  bool get shouldPlay =>
      enabled && theme != null && AudioThemes.available.contains(theme);

  AudioState copyWith({bool? enabled, AudioTheme? theme, double? volume}) =>
      AudioState(
        enabled: enabled ?? this.enabled,
        theme: theme ?? this.theme,
        volume: volume ?? this.volume,
      );
}

/// The one place that decides whether a sound is playing (scope §1).
///
/// Three rules. Ambience is off until it is asked for, so nobody is surprised
/// by noise. It stops when the app goes into the background and resumes only if
/// it was playing before, so a phone put down goes quiet. And a theme with no
/// licensed file is not offered at all — silence rather than a dead button.
class AudioController extends Notifier<AudioState> with WidgetsBindingObserver {
  bool _wasPlaying = false;

  @override
  AudioState build() {
    final repo = ref.watch(audioPreferencesRepositoryProvider);
    final state = repo.read();

    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    // Nothing starts on its own here: the first frame is silent, and playback
    // begins when this state says so through [start].
    return state;
  }

  AmbientAudio get _player => ref.read(ambientAudioProvider);
  AudioPreferencesRepository get _repo =>
      ref.read(audioPreferencesRepositoryProvider);

  /// Starts or stops the bed to match the current choice.
  Future<void> apply() async {
    final wanted = state;
    if (!wanted.shouldPlay) {
      _wasPlaying = false;
      await _player.stop();
      return;
    }
    _wasPlaying = true;
    await _player.play(wanted.theme!.assetPath, volume: wanted.volume);
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _repo.save(state);
    await apply();
  }

  Future<void> chooseTheme(AudioTheme theme) async {
    state = state.copyWith(theme: theme);
    await _repo.save(state);
    await apply();
  }

  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume.clamp(0, 1).toDouble());
    await _repo.save(state);
    await _player.setVolume(state.volume);
  }

  /// A moment inside a ritual. Silent unless the file exists and sound is on.
  Future<void> playRitual(RitualSound sound) async {
    if (!state.enabled || !AudioThemes.canPlay(sound)) return;
    await _player.playOnce(sound.assetPath, volume: state.volume);
  }

  /// Focus handling: a phone put down goes quiet, and only what was playing
  /// comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.resumed:
        if (_wasPlaying) apply();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        final resume = _wasPlaying;
        _player.stop();
        _wasPlaying = resume;
    }
  }
}

final audioControllerProvider = NotifierProvider<AudioController, AudioState>(
  AudioController.new,
);
