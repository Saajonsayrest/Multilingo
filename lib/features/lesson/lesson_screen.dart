import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mascot.dart';
import '../../core/speech.dart';
import '../../core/symbols.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/levels.dart';
import '../../domain/models.dart';
import '../../domain/quests.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/cloud_sync.dart';
import '../../state/controller.dart';
import '../settings/account_screen.dart';
import 'exercise_widgets.dart';

/// Runs a list of exercises: grade, feedback, hearts, retry of mistakes, and
/// the final reward screen.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.title,
    required this.exercises,
    this.lessonId,
    this.kind = SessionKind.lesson,
    this.levelId,
  });

  final String title;
  final List<Exercise> exercises;
  final String? lessonId;
  final SessionKind kind;

  /// For checkpoints: the CEFR level being tested.
  final String? levelId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late final List<Exercise> _queue = [...widget.exercises];
  // "New word" cards are not questions, so they never count as planned.
  late final int _planned = widget.exercises.where((e) => !e.isTeach).length;
  int _index = 0;
  int _firstTryCorrect = 0;
  int _mistakes = 0;
  int _combo = 0;
  int _maxCombo = 0;
  final _correctWords = <String>[];
  final _wrongWords = <String>[];
  final _retried = <Exercise>{};

  String? _answer;
  bool _graded = false;
  bool _wasCorrect = false;
  Reward? _reward;
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  Exercise get _current => _queue[_index];
  bool get _practice => widget.kind != SessionKind.lesson;
  bool get _done => _reward != null;

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  int _hearts() => ref.read(appProvider).heartsAt(ref.read(clockProvider)());

  void _check() {
    if (_answer == null || _graded) return;
    final ok = _current.check(_answer!);
    final fb = ref.read(feedbackProvider);
    setState(() {
      _graded = true;
      _wasCorrect = ok;
    });
    if (ok) {
      fb.correct();
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      if (!_retried.contains(_current)) _firstTryCorrect++;
      _correctWords.addAll(_current.wordIds);
    } else {
      fb.wrong();
      _combo = 0;
      _mistakes++;
      _wrongWords.addAll(_current.wordIds);
      if (!_practice) ref.read(appProvider.notifier).loseHeart();
      // Give the learner one more try at the end.
      if (_retried.add(_current)) _queue.add(_current);
    }
  }

  void _onMatchMistake() {
    _mistakes++;
    _combo = 0;
    _wrongWords.addAll(_current.wordIds);
    if (!_practice) {
      ref.read(appProvider.notifier).loseHeart();
      if (_hearts() <= 0) _outOfHearts();
    }
  }

  Future<void> _next() async {
    if (!_practice && _hearts() <= 0) {
      if (!await _outOfHearts()) return;
    }
    if (_index + 1 >= _queue.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _answer = null;
      _graded = false;
    });
  }

  void _finish() {
    final r = ref.read(appProvider.notifier).finishSession(
          LessonResult(
            lessonId: widget.lessonId,
            correct: _planned - _mistakeExercises(),
            total: _planned,
            correctWordIds: _correctWords,
            wrongWordIds: _wrongWords,
            maxCombo: _maxCombo,
            kind: widget.kind,
            levelId: widget.levelId,
          ),
        );
    setState(() => _reward = r);
    _confetti.play();
  }

  /// Exercises that were failed at least once (match mistakes included).
  int _mistakeExercises() => _mistakes.clamp(0, _planned);

  /// Returns true when the learner refilled hearts and can carry on.
  Future<bool> _outOfHearts() async {
    if (!mounted) return false;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(children: [Mascot(mood: MascotMood.reassured, size: 56), SizedBox(width: 10), Expanded(child: Text('Out of hearts'))]),
        content: Text(
          'Practice an easy review to win a heart back, '
          'or refill all hearts for $heartRefillGems gems.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'quit'),
            child: const Text('Leave lesson'),
          ),
          if (ref.read(appProvider).gems >= heartRefillGems)
            FilledButton(
              onPressed: () => Navigator.pop(context, 'refill'),
              child: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Refill'),
                glyphSpan(Glyph.gem),
              ])),
            ),
        ],
      ),
    );
    if (!mounted) return false;
    if (choice == 'refill') {
      return ref.read(appProvider.notifier).refillHeartsWithGems();
    }
    Navigator.of(context).pop();
    return false;
  }

  Future<bool> _confirmQuit() async {
    if (_done) return true;
    final quit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit this lesson?'),
        content: const Text('You will lose the progress of this session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    return quit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider);
    final hearts = s.heartsAt(ref.read(clockProvider)());
    return PopScope(
      canPop: _done,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmQuit()) nav.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: _done ? _results(context) : _lesson(context, hearts),
        ),
      ),
    );
  }

  Widget _lesson(BuildContext context, int hearts) {
    final progress = (_index + (_graded && _wasCorrect ? 1 : 0)) / _queue.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  if (await _confirmQuit()) nav.pop();
                },
              ),
              Expanded(child: ProgressBar(value: progress)),
              const SizedBox(width: 12),
              if (!_practice) StatChip(glyph: Glyph.heart, value: '$hearts', color: Palette.tomato),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: ExerciseBody(
              key: ValueKey('$_index-${_current.hashCode}'),
              exercise: _current,
              locked: _graded,
              revealed: _graded ? _answer : null,
              onChanged: (v) => setState(() => _answer = v),
              onMistake: _onMatchMistake,
            ),
          ),
        ),
        _bottomBar(context),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    if (_current.isTeach) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: BigButton(label: 'Continue', onPressed: _next),
      );
    }
    final ok = _wasCorrect;
    final color = ok ? Palette.olive : Palette.tomato;
    final dark = ok ? Palette.oliveDark : Palette.tomatoDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      color: _graded ? color.withValues(alpha: 0.16) : Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_graded) ...[
            Row(
              children: [
                GlyphIcon(ok ? Glyph.correct : Glyph.incorrect, size: 34),
                const SizedBox(width: 8),
                Text(
                  ok ? _praise() : 'Not quite',
                  style: TextStyle(
                      color: dark, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                if (ok && _combo >= 3) ...[
                  const Spacer(),
                  Text.rich(
                    TextSpan(children: [
                      glyphSpan(Glyph.streak, size: 20),
                      TextSpan(text: '$_combo in a row'),
                    ]),
                    style: TextStyle(color: dark, fontWeight: FontWeight.w800),
                  ),
                ],
              ],
            ),
            if (!ok)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  'Correct answer: ${_current.answer}',
                  style: TextStyle(color: dark, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 10),
          ],
          BigButton(
            label: _graded ? 'Continue' : 'Check',
            color: _graded ? color : Palette.teal,
            shadow: _graded ? dark : Palette.tealDark,
            onPressed: _graded ? _next : (_answer == null ? null : _check),
          ),
        ],
      ),
    );
  }

  String _praise() {
    const lines = ['Great!', 'Perfetto!', 'Bravo!', 'Esatto!', 'Ottimo!'];
    return lines[(_index + _combo) % lines.length];
  }

  // ---- results -----------------------------------------------------------------------------

  Widget _results(BuildContext context) {
    final r = _reward!;
    final isCheckpoint = r.checkpointLevel != null;
    final accuracy = isCheckpoint
        ? r.accuracyPercent
        : (_firstTryCorrect / _planned * 100).round().clamp(0, 100);
    final String headline;
    final MascotMood mood;
    if (isCheckpoint) {
      mood = r.checkpointPassed ? MascotMood.congratulating : MascotMood.reassured;
      headline = r.checkpointPassed
          ? '${r.checkpointLevel} checkpoint passed!'
          : 'Not yet. Score ${(checkpointPassMark * 100).round()}% to pass.';
    } else {
      mood = _mistakes == 0 ? MascotMood.celebrating : MascotMood.proud;
      headline = _mistakes == 0 ? 'Perfect lesson!' : 'Lesson complete!';
    }
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Mascot(mood: mood, size: 170),
              const SizedBox(height: 8),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _stat(Glyph.xp, '+${r.xp}', 'XP${r.boosted ? ' (x2)' : ''}', Palette.lemonDark),
                  _stat(Glyph.goal, '$accuracy%', 'Accuracy', Palette.olive),
                  _stat(Glyph.gem, '+${r.gems}', 'Gems', Palette.gem),
                ],
              ),
              const SizedBox(height: 20),
              if (r.streakIncreased)
                _banner('${r.streak} day streak!', Palette.tomato, glyph: Glyph.streak),
              if (r.goalJustMet)
                _banner('Daily goal reached', Palette.olive, glyph: Glyph.goal),
              if (r.checkpointPassed)
                _banner('Next level unlocked', Palette.olive)
              else if (isCheckpoint)
                _banner('Review your mistakes in Practice, then try again.', Palette.tomato),
              for (final id in r.newAchievements)
                _banner(
                  'Badge unlocked: ${_badgeName(id)}',
                  Palette.sky,
                  glyph: Glyph.badge,
                ),
              if (ref.watch(accountHintProvider) case final hint?)
                _accountBanner(context, hint),
              const Spacer(),
              BigButton(
                label: 'Continue',
                onPressed: () {
                  ref.read(accountHintProvider.notifier).clear();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.05,
          numberOfParticles: 18,
          colors: const [Palette.tomato, Palette.lemon, Palette.teal, Palette.olive],
        ),
      ],
    );
  }

  /// "10 lessons done" - a reminder to add an email so the progress can be
  /// found again on a new phone. Tapping it opens Account and cloud save.
  Widget _accountBanner(BuildContext context, String milestone) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Palette.teal.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              ref.read(accountHintProvider.notifier).clear();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_rounded, color: Palette.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).accountHint(milestone),
                      style: const TextStyle(
                        color: Palette.teal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  String _badgeName(String id) =>
      achievementDefs.firstWhere((a) => a.id == id).title;

  Widget _stat(Glyph glyph, String value, String label, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlyphIcon(glyph, size: 26),
                  const SizedBox(width: 6),
                  Text(value,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _banner(String text, Color color, {Glyph? glyph}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text.rich(
          TextSpan(children: [
            if (glyph != null) glyphSpan(glyph, size: 22),
            TextSpan(text: text),
          ]),
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      );
}
