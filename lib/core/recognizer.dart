import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Picks the recogniser locale id that matches [wanted] (like 'de-DE').
///
/// Phones report ids as 'de_DE' or 'de-DE'. The exact language and country
/// is preferred, then any country of the same language. Null means the
/// phone has no recogniser for that language, so the default is used.
String? pickLocale(List<String> available, String wanted) {
  String norm(String s) => s.replaceAll('_', '-').toLowerCase();
  final want = norm(wanted);
  for (final id in available) {
    if (norm(id) == want) return id;
  }
  final language = want.split('-').first;
  for (final id in available) {
    if (norm(id).split('-').first == language) return id;
  }
  return null;
}

/// Listens to the microphone and turns speech into text. An interface so
/// tests can pretend to speak.
abstract class Recognizer {
  /// Starts listening. [onResult] gets the words heard so far and whether
  /// that is the final result. Returns false when the microphone or speech
  /// recognition is not available (no permission, no recogniser).
  Future<bool> start({
    required String locale,
    required void Function(String words, bool isFinal) onResult,
    required void Function(String error) onError,
  });

  Future<void> stop();
  Future<void> cancel();
}

class SttRecognizer implements Recognizer {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  void Function(String)? _onError;

  @override
  Future<bool> start({
    required String locale,
    required void Function(String words, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {
    _onError = onError;
    try {
      if (!_ready) {
        _ready = await _stt.initialize(onError: (e) => _onError?.call(e.errorMsg));
      }
      if (!_ready) return false;
      final ids = (await _stt.locales()).map((l) => l.localeId).toList();
      await _stt.listen(
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: pickLocale(ids, locale),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }

  @override
  Future<void> cancel() async {
    try {
      await _stt.cancel();
    } catch (_) {}
  }
}

final recognizerProvider = Provider<Recognizer>((ref) {
  final r = SttRecognizer();
  ref.onDispose(r.cancel);
  return r;
});
