import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../state/controller.dart';
import '../state/course_state.dart';

/// Text-to-speech in the language being learned. Failures are swallowed on
/// purpose: a missing voice must never break a lesson.
class Speech {
  Speech(this._enabled, this._locale) {
    _init();
  }

  final bool Function() _enabled;
  final String _locale;
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  double _rate = 0.42;

  Future<void> _init() async {
    try {
      await _tts.setLanguage(_locale);
      await _tts.setSpeechRate(0.42);
      await _tts.awaitSpeakCompletion(false);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> speak(String text, {bool slow = false}) async {
    if (!_enabled() || !_ready) return;
    try {
      await _tts.stop();
      // Only talk to the voice engine when the speed really changes.
      final rate = slow ? 0.25 : 0.42;
      if (rate != _rate) {
        await _tts.setSpeechRate(rate);
        _rate = rate;
      }
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

final speechProvider = Provider<Speech>((ref) {
  // A new voice is made when the language changes.
  final locale = ref.watch(courseProvider).language.ttsLocale;
  final s = Speech(() => ref.read(appProvider).speechOn, locale);
  ref.onDispose(s.stop);
  return s;
});

/// Haptic and click feedback that respects the settings.
class Feedback {
  Feedback(this._ref);

  final Ref _ref;

  void correct() {
    final s = _ref.read(appProvider);
    if (s.hapticsOn) HapticFeedback.lightImpact();
    if (s.soundOn) SystemSound.play(SystemSoundType.click);
  }

  void wrong() {
    final s = _ref.read(appProvider);
    if (s.hapticsOn) HapticFeedback.heavyImpact();
  }

  void tap() {
    if (_ref.read(appProvider).hapticsOn) HapticFeedback.selectionClick();
  }
}

final feedbackProvider = Provider<Feedback>((ref) => Feedback(ref));
