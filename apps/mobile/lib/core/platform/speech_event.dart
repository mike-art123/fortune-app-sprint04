/// What the microphone reports back (scope §3).
///
/// Only recognised text ever crosses this boundary — no audio is recorded,
/// kept or sent anywhere by the app. The browser hears; we receive words.
sealed class SpeechEvent {
  const SpeechEvent();
}

/// Something was heard. [isFinal] marks the browser's settled reading; the
/// interim ones are shown as they arrive so speaking feels answered.
final class SpeechHeard extends SpeechEvent {
  const SpeechHeard(this.text, {this.isFinal = false});

  final String text;
  final bool isFinal;
}

/// Listening is over, for the reason given.
final class SpeechEnded extends SpeechEvent {
  const SpeechEnded(this.reason);

  final SpeechEndReason reason;
}

enum SpeechEndReason {
  /// The browser finished on its own.
  finished,

  /// We stopped it (the person tapped stop, or left).
  cancelled,

  /// Nothing was heard for a while.
  timeout,

  /// Nothing was said at all.
  noSpeech,

  /// Microphone permission was refused.
  denied,

  /// This browser cannot listen.
  unsupported,

  /// Anything else — say so plainly, never blame the person.
  failed,
}
