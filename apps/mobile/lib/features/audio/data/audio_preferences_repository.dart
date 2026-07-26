import '../../../core/constants/storage_keys.dart';
import '../../../core/persistence/local_storage.dart';
import '../application/audio_controller.dart';
import '../domain/audio_theme.dart';

/// Persists the ambient-sound choice on the device (scope §1).
///
/// Device-level on purpose: whether a phone should make noise belongs to the
/// phone, not to the account. Volume is stored in whole percent because an
/// integer survives every storage backend without a rounding story.
class AudioPreferencesRepository {
  const AudioPreferencesRepository(this._storage);

  final LocalStorage _storage;

  static const double defaultVolume = 0.4;

  AudioState read() {
    final stored = audioThemeFromId(_storage.getString(PrefKeys.audioTheme));
    final percent = _storage.getInt(PrefKeys.audioVolume);
    return AudioState(
      // Silence is the default. Sound is something somebody turns on.
      enabled: _storage.getBool(PrefKeys.audioEnabled) ?? false,
      theme: stored ?? _firstAvailable(),
      volume: percent == null
          ? defaultVolume
          : (percent / 100).clamp(0, 1).toDouble(),
    );
  }

  Future<void> save(AudioState state) async {
    await _storage.setBool(PrefKeys.audioEnabled, state.enabled);
    await _storage.setInt(PrefKeys.audioVolume, (state.volume * 100).round());
    final theme = state.theme;
    if (theme != null) await _storage.setString(PrefKeys.audioTheme, theme.id);
  }

  /// A sensible starting bed, but only among the ones actually licensed.
  static AudioTheme? _firstAvailable() {
    final available = AudioThemes.available;
    return available.isEmpty ? null : available.first;
  }
}
