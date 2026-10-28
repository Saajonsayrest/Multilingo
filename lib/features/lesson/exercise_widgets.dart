import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/recognizer.dart';
import '../../core/speech.dart';
import '../../domain/speech_match.dart';
import '../../state/course_state.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';

/// Renders one exercise. Reports the learner's current answer through
/// [onChanged] (null while incomplete). The lesson screen decides when to
/// grade it. [onMistake] fires for wrong taps that are graded instantly
/// (match pairs).
class ExerciseBody extends ConsumerStatefulWidget {
  const ExerciseBody({
    super.key,
    required this.exercise,
    required this.onChanged,
    required this.onMistake,
    required this.locked,
    this.revealed,
  });

  final Exercise exercise;
  final ValueChanged<String?> onChanged;
  final VoidCallback onMistake;

  /// True after grading: inputs stop reacting.
  final bool locked;

  /// The graded choice, used to colour option buttons.
  final String? revealed;

  @override
  ConsumerState<ExerciseBody> createState() => _ExerciseBodyState();
}

class _ExerciseBodyState extends ConsumerState<ExerciseBody> {
  final _text = TextEditingController();
  final List<int> _picked = []; // indexes into options (tile exercises)
  String? _choice;
  bool _spoken = false;
  final Set<String> _matchedIt = {};
  String? _selIt;
  String? _selEn;
  String? _wrongIt;
  String? _wrongEn;
  Word? _hintWord; // the word whose meaning is shown (tap-a-word hints)
  late final Recognizer _recognizer = ref.read(recognizerProvider);
  bool _listening = false;
  String _heard = '';
  String? _micNote;
  late final List<String> _enOrder;

  Exercise get ex => widget.exercise;

  @override
  void initState() {
    super.initState();
    _enOrder = ex.pairs.map((p) => p[1]).toList()..shuffle(Random());
    final autoPlay = const {
      ExerciseType.listenType,
      ExerciseType.listenSelect,
      ExerciseType.translateToEn,
      ExerciseType.teach,
    }.contains(ex.type);
    if (autoPlay && ex.audioText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _say());
    }
  }

  @override
  void dispose() {
    if (_listening) _recognizer.cancel();
    _text.dispose();
    super.dispose();
  }

  void _say({bool slow = false}) {
    if (ex.audioText == null) return;
    ref.read(speechProvider).speak(ex.audioText!, slow: slow);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _title(),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Expanded(child: SingleChildScrollView(child: _body(context))),
      ],
    );
  }

  String _title() => switch (ex.type) {
        ExerciseType.translateToEn => 'Translate into English',
        ExerciseType.translateToIt =>
          'Translate into ${ref.read(courseProvider).language.name}',
        ExerciseType.multipleChoice => 'Choose the answer',
        ExerciseType.matchPairs => 'Match the pairs',
        ExerciseType.listenType => 'Write what you hear',
        ExerciseType.listenSelect => 'What do you hear?',
        ExerciseType.fillGap => 'Fill in the blank',
        ExerciseType.pictureSelect => 'Which one is this?',
        ExerciseType.speak => 'Say it out loud',
        ExerciseType.teach => 'New word',
      };

  Widget _body(BuildContext context) => switch (ex.type) {
        ExerciseType.translateToEn ||
        ExerciseType.translateToIt =>
          _tiles(context),
        ExerciseType.multipleChoice ||
        ExerciseType.pictureSelect ||
        ExerciseType.listenSelect ||
        ExerciseType.fillGap =>
          _choices(context),
        ExerciseType.matchPairs => _match(context),
        ExerciseType.listenType => _listenType(context),
        ExerciseType.speak => _speak(context),
        ExerciseType.teach => _teach(context),
      };

  // ---- tap-a-word hints --------------------------------------------------------

  /// An Italian sentence where every word the course teaches has a dotted
  /// underline. Tapping one speaks it and shows its meaning underneath.
  Widget _hinted(String sentence, double fontSize) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800);
    final shown = _hintWord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            for (final p in ref.read(courseProvider).hintPieces(sentence))
              p.word == null
                  ? Text('${p.text} ', style: style)
                  : GestureDetector(
                      onTap: () {
                        setState(() => _hintWord = p.word);
                        ref.read(speechProvider).speak(p.word!.it);
                      },
                      child: Text(
                        '${p.text} ',
                        style: style.copyWith(
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                          decorationColor: Palette.sky,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
          ],
        ),
        if (shown != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Palette.sky.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${shown.it} = ${shown.en}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  // ---- new word card -----------------------------------------------------------

  /// Shows the word, its meaning and its sound. Nothing to answer.
  Widget _teach(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 12),
        if (ex.hint != null)
          Text(ex.hint!, style: const TextStyle(fontSize: 88)),
        const SizedBox(height: 16),
        Text(
          ex.prompt,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          ex.answer,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(color: Palette.teal),
        ),
        const SizedBox(height: 28),
        _speaker(big: true),
        const SizedBox(height: 12),
        Text('Tap to hear it again', style: theme.textTheme.bodySmall),
      ],
    );
  }

  // ---- shared bits -------------------------------------------------------------

  Widget _speaker({bool big = false}) => Row(
        mainAxisAlignment: big ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          IconButton.filled(
            tooltip: 'Play audio',
            iconSize: big ? 44 : 26,
            style: IconButton.styleFrom(
              backgroundColor: Palette.sky,
              padding: EdgeInsets.all(big ? 26 : 10),
            ),
            onPressed: () => _say(),
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Play slowly',
            onPressed: () => _say(slow: true),
            icon: const Icon(Icons.slow_motion_video_rounded),
          ),
        ],
      );

  Widget _option(
    String label, {
    required bool selected,
    required VoidCallback? onTap,
    Color? fill,
    Color? border,
    double fontSize = 17,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: fill ?? (selected ? scheme.primary.withValues(alpha: 0.12) : scheme.surface),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border ?? (selected ? scheme.primary : Palette.mist),
                width: 2,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  // ---- choice exercises ------------------------------------------------------------

  Widget _choices(BuildContext context) {
    final isPicture = ex.type == ExerciseType.pictureSelect;
    final prompt = switch (ex.type) {
      ExerciseType.pictureSelect => Center(
          child: Text(ex.prompt, style: const TextStyle(fontSize: 96)),
        ),
      ExerciseType.listenSelect => _speaker(big: true),
      ExerciseType.fillGap => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hinted(ex.prompt, 24),
            if (ex.hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(ex.hint!,
                    style: TextStyle(color: Theme.of(context).hintColor)),
              ),
          ],
        ),
      _ => Row(
          children: [
            if (ex.audioText != null) ...[_speaker(), const SizedBox(width: 6)],
            Expanded(
              child: Text(ex.prompt,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
    };
    final grid = isPicture;
    final children = [
      for (final o in ex.options)
        _option(
          o,
          selected: _choice == o,
          fill: _revealFill(o),
          border: _revealBorder(o),
          onTap: widget.locked
              ? null
              : () {
                  setState(() => _choice = o);
                  widget.onChanged(o);
                },
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        prompt,
        const SizedBox(height: 22),
        if (grid)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: children,
          )
        else
          for (final c in children)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: c),
      ],
    );
  }

  Color? _revealFill(String option) {
    if (!widget.locked || widget.revealed == null) return null;
    if (normalize(option) == normalize(ex.answer)) {
      return Palette.olive.withValues(alpha: 0.2);
    }
    if (option == widget.revealed) return Palette.tomato.withValues(alpha: 0.15);
    return null;
  }

  Color? _revealBorder(String option) {
    if (!widget.locked || widget.revealed == null) return null;
    if (normalize(option) == normalize(ex.answer)) return Palette.olive;
    if (option == widget.revealed) return Palette.tomato;
    return null;
  }

  // ---- tile exercises -----------------------------------------------------------------

  Widget _tiles(BuildContext context) {
    final toIt = ex.type == ExerciseType.translateToIt;
    final chosen = [for (final i in _picked) ex.options[i]];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (!toIt) ...[_speaker(), const SizedBox(width: 6)],
            Expanded(
              child: toIt
                  ? Text(ex.prompt,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))
                  : _hinted(ex.prompt, 22),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: Palette.mist, width: 2),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var k = 0; k < _picked.length; k++)
                _option(
                  chosen[k],
                  selected: false,
                  onTap: widget.locked ? null : () => _unpick(k),
                  fontSize: 16,
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < ex.options.length; i++)
              Opacity(
                opacity: _picked.contains(i) ? 0.25 : 1,
                child: _option(
                  ex.options[i],
                  selected: false,
                  onTap: widget.locked || _picked.contains(i) ? null : () => _pick(i),
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _pick(int i) {
    ref.read(feedbackProvider).tap();
    setState(() => _picked.add(i));
    _emitTiles();
  }

  void _unpick(int k) {
    setState(() => _picked.removeAt(k));
    _emitTiles();
  }

  void _emitTiles() => widget.onChanged(
        _picked.isEmpty ? null : _picked.map((i) => ex.options[i]).join(' '),
      );

  // ---- listen & type -----------------------------------------------------------------------

  Widget _listenType(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _speaker(big: true),
          const SizedBox(height: 26),
          TextField(
            controller: _text,
            enabled: !widget.locked,
            autofocus: false,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type in ${ref.read(courseProvider).language.name}',
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => widget.onChanged(v.trim().isEmpty ? null : v),
          ),
          const SizedBox(height: 8),
          Text(
            'Accents and punctuation do not matter.',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
        ],
      );

  // ---- match pairs ------------------------------------------------------------------------------

  Widget _match(BuildContext context) {
    final its = ex.pairs.map((p) => p[0]).toList();
    Widget tile(String label, bool isIt) {
      final done = isIt
          ? _matchedIt.contains(label)
          : _matchedIt.any((it) => ex.pairs.firstWhere((p) => p[0] == it)[1] == label);
      final selected = isIt ? _selIt == label : _selEn == label;
      final wrong = isIt ? _wrongIt == label : _wrongEn == label;
      return Opacity(
        opacity: done ? 0.3 : 1,
        child: _option(
          label,
          selected: selected,
          border: wrong ? Palette.tomato : null,
          fill: wrong ? Palette.tomato.withValues(alpha: 0.12) : null,
          onTap: widget.locked || done ? null : () => _tapMatch(label, isIt),
          fontSize: 16,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(children: [
            for (final w in its)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: tile(w, true)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(children: [
            for (final w in _enOrder)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: tile(w, false)),
          ]),
        ),
      ],
    );
  }

  Future<void> _tapMatch(String label, bool isIt) async {
    ref.read(feedbackProvider).tap();
    if (isIt) {
      ref.read(speechProvider).speak(label);
      setState(() => _selIt = label);
    } else {
      setState(() => _selEn = label);
    }
    if (_selIt == null || _selEn == null) return;
    final it = _selIt!;
    final en = _selEn!;
    final ok = ex.pairs.any((p) => p[0] == it && p[1] == en);
    if (ok) {
      ref.read(feedbackProvider).correct();
      setState(() {
        _matchedIt.add(it);
        _selIt = _selEn = null;
      });
      if (_matchedIt.length == ex.pairs.length) widget.onChanged(ex.answer);
    } else {
      ref.read(feedbackProvider).wrong();
      widget.onMistake();
      setState(() {
        _wrongIt = it;
        _wrongEn = en;
      });
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _wrongIt = _wrongEn = null;
        _selIt = _selEn = null;
      });
    }
  }

  // ---- speak ---------------------------------------------------------------------------------------

  Widget _speak(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ex.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          if (ex.hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(ex.hint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ),
          const SizedBox(height: 20),
          _speaker(big: true),
          const SizedBox(height: 24),
          Text(
            _listening
                ? 'Listening... say the phrase now'
                : 'Listen, then tap the microphone and say the phrase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 14),
          Center(
            child: IconButton.filled(
              tooltip: _listening ? 'Stop listening' : 'Speak',
              iconSize: 44,
              style: IconButton.styleFrom(
                backgroundColor: _listening ? Palette.tomato : Palette.teal,
                padding: const EdgeInsets.all(24),
              ),
              onPressed: widget.locked || _spoken ? null : _toggleMic,
              icon: Icon(
                _listening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
              ),
            ),
          ),
          if (_heard.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'I heard: "$_heard"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          if (_micNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _micNote!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.tomato, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 18),
          // For when the learner cannot speak now (a quiet place, no
          // microphone). It works on trust, like the old version.
          _option(
            _spoken ? 'I said it ✓' : 'I said it out loud',
            selected: _spoken,
            onTap: widget.locked
                ? null
                : () {
                    setState(() => _spoken = true);
                    widget.onChanged(ex.answer);
                  },
          ),
        ],
      );

  // ---- speaking with the microphone -----------------------------------------------

  Future<void> _toggleMic() async {
    if (_listening) {
      await _recognizer.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
      _micNote = null;
    });
    // Silence the app's own voice, but do not wait for it: the microphone
    // should start at once.
    unawaited(ref.read(speechProvider).stop());
    final started = await _recognizer.start(
      locale: ref.read(courseProvider).language.ttsLocale,
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() => _heard = words);
        if (isFinal) _judgeSpeech(words);
      },
      onError: (_) {
        if (!mounted || !_listening) return;
        setState(() {
          _listening = false;
          _micNote = 'I could not hear you. Try again, or use the button below.';
        });
      },
    );
    if (!started && mounted) {
      setState(() {
        _listening = false;
        _micNote = 'The microphone is not available. Allow it in your phone '
            'settings, or use the button below.';
      });
    }
  }

  void _judgeSpeech(String words) {
    if (speechPasses(words, ex.answer)) {
      setState(() {
        _listening = false;
        _spoken = true;
        _micNote = null;
      });
      widget.onChanged(ex.answer);
    } else {
      setState(() {
        _listening = false;
        _micNote = 'Not quite. Listen once more, then try again.';
      });
      widget.onChanged(null);
    }
  }
}
