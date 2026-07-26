import 'speech_event.dart';
import 'speech_recognition.dart';

/// The microphone, as the search bar sees it (scope §3).
///
/// An interface rather than a direct call so a test can speak without a
/// browser, and so the platform details stay in one place.
abstract interface class SpeechInput {
  /// Whether this build can listen at all. When false the app never offers a
  /// microphone — no dead button, no permission prompt.
  bool get isSupported;

  /// Listens until the browser settles, the person stops, or [silence] passes
  /// with nothing heard. Cancelling the subscription stops the microphone.
  Stream<SpeechEvent> listen({
    required String locale,
    required Duration silence,
  });
}

class PlatformSpeechInput implements SpeechInput {
  const PlatformSpeechInput();

  @override
  bool get isSupported => isSpeechRecognitionSupported;

  @override
  Stream<SpeechEvent> listen({
    required String locale,
    required Duration silence,
  }) {
    // The timer restarts on every word, so a long sentence is never cut off —
    // only an actually silent microphone gives up.
    return recognizeSpeech(locale: locale).timeout(
      silence,
      onTimeout: (sink) {
        sink.add(const SpeechEnded(SpeechEndReason.timeout));
        sink.close();
      },
    );
  }
}
