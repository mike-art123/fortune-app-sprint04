/// The seven ambient beds the app offers (scope §1).
///
/// The list is the product decision; the files are an external dependency the
/// owner supplies under licence. Until a theme's file is bundled it is simply
/// not offered — see [AudioThemes.available]. Nothing here ever guesses at a
/// path or falls back to a different sound: a bed nobody licensed is silence,
/// and silence is an honest answer.
enum AudioTheme { night, rain, candle, nature, persian, santurNey, piano }

extension AudioThemeInfo on AudioTheme {
  String get id => switch (this) {
        AudioTheme.night => 'night',
        AudioTheme.rain => 'rain',
        AudioTheme.candle => 'candle',
        AudioTheme.nature => 'nature',
        AudioTheme.persian => 'persian',
        AudioTheme.santurNey => 'santur-ney',
        AudioTheme.piano => 'piano',
      };

  String get labelFa => switch (this) {
        AudioTheme.night => 'شب',
        AudioTheme.rain => 'باران',
        AudioTheme.candle => 'شمع',
        AudioTheme.nature => 'طبیعت',
        AudioTheme.persian => 'ایرانی',
        AudioTheme.santurNey => 'سنتور و نی',
        AudioTheme.piano => 'پیانو',
      };

  /// Where the licensed file will live. One naming rule, no exceptions, so
  /// adding a bed is dropping a file in and listing it in `pubspec.yaml`.
  String get assetPath => 'assets/audio/ambient/$id.mp3';
}

AudioTheme? audioThemeFromId(String? id) {
  for (final theme in AudioTheme.values) {
    if (theme.id == id) return theme;
  }
  return null;
}

/// One-shot sounds that mark a moment in a ritual (scope §1).
enum RitualSound { offering, reveal }

extension RitualSoundInfo on RitualSound {
  String get id => switch (this) {
        RitualSound.offering => 'offering',
        RitualSound.reveal => 'reveal',
      };

  String get assetPath => 'assets/audio/ritual/$id.mp3';
}

abstract final class AudioThemes {
  /// The audio assets this build actually bundles.
  ///
  /// This set and the `assets:` list in `pubspec.yaml` are the same fact stated
  /// twice, so a test compares them: add a file, and the test says exactly what
  /// else to update.
  ///
  /// «طبیعت» is absent on purpose — the owner did not want it. The theme stays
  /// in the enum because the scope names it; leaving its file out is all it
  /// takes for the app to stop offering it.
  static const Set<String> bundled = <String>{
    'assets/audio/ambient/night.mp3',
    'assets/audio/ambient/rain.mp3',
    'assets/audio/ambient/candle.mp3',
    'assets/audio/ambient/persian.mp3',
    'assets/audio/ambient/santur-ney.mp3',
    'assets/audio/ambient/piano.mp3',
    'assets/audio/ritual/offering.mp3',
    'assets/audio/ritual/reveal.mp3',
  };

  /// The themes this build can actually play. Deliberately derived rather than
  /// declared: a theme cannot be offered by mistake.
  static List<AudioTheme> get available => AudioTheme.values
      .where((theme) => bundled.contains(theme.assetPath))
      .toList(growable: false);

  static bool get hasAny => available.isNotEmpty;

  static bool canPlay(RitualSound sound) => bundled.contains(sound.assetPath);
}
