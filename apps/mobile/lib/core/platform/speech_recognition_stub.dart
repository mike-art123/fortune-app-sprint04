import 'speech_event.dart';

/// Non-web resolution: listening needs the browser's speech engine, so outside
/// a web build the microphone is simply never offered. Never a crash.
bool get isSpeechRecognitionSupported => false;

Stream<SpeechEvent> recognizeSpeech({required String locale}) {
  return Stream.value(const SpeechEnded(SpeechEndReason.unsupported));
}
