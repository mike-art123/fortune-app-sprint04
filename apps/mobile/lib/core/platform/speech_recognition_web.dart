import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'speech_event.dart';

/// Web resolution: the browser's Web Speech API (scope §3).
///
/// Compiled ONLY for the web target, via the conditional export in
/// `speech_recognition.dart`. The VM/stub build never loads this file, so
/// `flutter test` and native targets keep reporting "cannot listen".
///
/// No audio is recorded or kept — the browser recognises locally or through
/// its own service and hands back text; the app only ever sees the words.
bool get isSpeechRecognitionSupported => _recognitionClass() != null;

JSFunction? _recognitionClass() {
  final standard = globalContext.getProperty<JSFunction?>(
    'SpeechRecognition'.toJS,
  );
  if (standard != null) return standard;
  return globalContext.getProperty<JSFunction?>('webkitSpeechRecognition'.toJS);
}

Stream<SpeechEvent> recognizeSpeech({required String locale}) {
  final factory = _recognitionClass();
  if (factory == null) {
    return Stream.value(const SpeechEnded(SpeechEndReason.unsupported));
  }

  final controller = StreamController<SpeechEvent>();
  JSObject? recognition;
  var finished = false;

  void end(SpeechEndReason reason) {
    if (finished) return;
    finished = true;
    controller.add(SpeechEnded(reason));
    controller.close();
  }

  // Leaving the field, tapping stop or disposing the widget all cancel the
  // subscription — that must also stop the microphone, not just ignore it.
  controller.onCancel = () {
    finished = true;
    try {
      recognition?.callMethod<JSAny?>('abort'.toJS);
    } catch (_) {
      // Already gone; nothing left to stop.
    }
  };

  try {
    final instance = factory.callAsConstructor<JSObject>();
    recognition = instance;
    instance.setProperty('lang'.toJS, locale.toJS);
    instance.setProperty('interimResults'.toJS, true.toJS);
    instance.setProperty('continuous'.toJS, false.toJS);
    instance.setProperty('maxAlternatives'.toJS, 1.toJS);

    instance.setProperty(
      'onresult'.toJS,
      ((JSObject event) {
        if (finished) return;
        final heard = _readTranscript(event);
        if (heard != null) controller.add(heard);
      }).toJS,
    );

    instance.setProperty(
      'onerror'.toJS,
      ((JSObject event) {
        final code = event.getProperty<JSString?>('error'.toJS)?.toDart ?? '';
        end(_reasonFor(code));
      }).toJS,
    );

    instance.setProperty(
      'onend'.toJS,
      (() => end(SpeechEndReason.finished)).toJS,
    );

    instance.callMethod<JSAny?>('start'.toJS);
  } catch (_) {
    end(SpeechEndReason.failed);
  }

  return controller.stream;
}

/// The latest reading of what is being said. Only the newest result matters —
/// the browser keeps re-reporting the same utterance as it settles.
SpeechHeard? _readTranscript(JSObject event) {
  final results = event.getProperty<JSObject?>('results'.toJS);
  if (results == null) return null;
  final count = results.getProperty<JSNumber?>('length'.toJS)?.toDartInt ?? 0;
  if (count == 0) return null;

  final result = results.callMethod<JSObject?>('item'.toJS, (count - 1).toJS);
  if (result == null) return null;
  final alternative = result.callMethod<JSObject?>('item'.toJS, 0.toJS);
  final text = alternative?.getProperty<JSString?>('transcript'.toJS)?.toDart;
  if (text == null || text.trim().isEmpty) return null;

  final isFinal =
      result.getProperty<JSBoolean?>('isFinal'.toJS)?.toDart ?? false;
  return SpeechHeard(text.trim(), isFinal: isFinal);
}

SpeechEndReason _reasonFor(String code) => switch (code) {
      'not-allowed' || 'service-not-allowed' => SpeechEndReason.denied,
      'no-speech' => SpeechEndReason.noSpeech,
      'aborted' => SpeechEndReason.cancelled,
      _ => SpeechEndReason.failed,
    };
