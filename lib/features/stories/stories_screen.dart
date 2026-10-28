import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/speech.dart' show feedbackProvider, speechProvider;
import '../../core/symbols.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';

/// List of short Italian stories. Finished stories show a check mark.
class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(appProvider).storiesDone;
    final stories = ref.watch(courseProvider).stories;
    return Scaffold(
      appBar: AppBar(title: const Text('Stories')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: stories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final story = stories[i];
          return _StoryCard(
            story: story,
            done: done.contains(story.id),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StoryPlayer(story: story),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.done,
    required this.onTap,
  });

  final StoryDef story;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: done ? '${story.title}, completed' : story.title,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(story.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${story.lines.length} lines, '
                        '${story.questions.length} questions',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (done)
                  const GlyphIcon(Glyph.correct, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Phase { dialogue, questions, results }

enum _OptionState { idle, correct, wrong, dimmed }

/// Plays one story: dialogue first, then its questions, then a results view.
class StoryPlayer extends ConsumerStatefulWidget {
  const StoryPlayer({super.key, required this.story});

  final StoryDef story;

  @override
  ConsumerState<StoryPlayer> createState() => _StoryPlayerState();
}

class _StoryPlayerState extends ConsumerState<StoryPlayer> {
  final ScrollController _scroll = ScrollController();
  _Phase _phase = _Phase.dialogue;

  /// How many dialogue lines are on screen.
  int _shown = 0;

  /// Indexes of lines whose English text the learner has revealed.
  final Set<int> _translated = {};

  int _q = 0;
  int? _picked;
  int _correct = 0;
  bool _finished = false;
  Reward? _reward;

  @override
  void initState() {
    super.initState();
    _shown = widget.story.lines.isEmpty ? 0 : 1;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _continueDialogue() {
    final total = widget.story.lines.length;
    if (_shown < total) {
      setState(() => _shown++);
      _scrollToEnd();
      return;
    }
    if (widget.story.questions.isEmpty) {
      _finish();
    } else {
      setState(() => _phase = _Phase.questions);
    }
  }

  void _pick(int index) {
    if (_picked != null) return;
    final question = widget.story.questions[_q];
    final isRight = index == question.answerIndex;
    final feedback = ref.read(feedbackProvider);
    if (isRight) {
      feedback.correct();
    } else {
      feedback.wrong();
    }
    setState(() {
      _picked = index;
      if (isRight) _correct++;
    });
  }

  void _nextQuestion() {
    if (_picked == null) return;
    if (_q < widget.story.questions.length - 1) {
      setState(() {
        _q++;
        _picked = null;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    final notifier = ref.read(appProvider.notifier);
    notifier.markStoryDone(widget.story.id);
    final reward = notifier.finishSession(
      LessonResult(
        correct: _correct,
        total: widget.story.questions.length,
        kind: SessionKind.story,
      ),
    );
    setState(() {
      _reward = reward;
      _phase = _Phase.results;
    });
  }

  _OptionState _optionState(int index, int answerIndex) {
    if (_picked == null) return _OptionState.idle;
    if (index == answerIndex) return _OptionState.correct;
    if (index == _picked) return _OptionState.wrong;
    return _OptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.story.title)),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.dialogue => _buildDialogue(),
          _Phase.questions => _buildQuestion(),
          _Phase.results => _buildResults(),
        },
      ),
    );
  }

  Widget _buildDialogue() {
    final lines = widget.story.lines;
    // The first speaker sits on the left, the next speaker on the right.
    final leftSpeakers = <String, bool>{};
    for (final line in lines) {
      leftSpeakers.putIfAbsent(line.speaker, () => leftSpeakers.length.isEven);
    }
    final progress = lines.isEmpty ? 1.0 : _shown / lines.length;

    return Column(
      children: [
        _ProgressStrip(value: progress),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _shown,
            itemBuilder: (context, i) {
              final line = lines[i];
              return _Bubble(
                line: line,
                alignLeft: leftSpeakers[line.speaker] ?? true,
                translated: _translated.contains(i),
                onReveal: () => setState(() => _translated.add(i)),
                onSpeak: () => ref.read(speechProvider).speak(line.it),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: BigButton(
            label: 'Continue',
            onPressed: _continueDialogue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    final theme = Theme.of(context);
    final questions = widget.story.questions;
    final question = questions[_q];
    final answered = _picked != null;
    final isRight = answered && _picked == question.answerIndex;
    final progress = (_q + (answered ? 1 : 0)) / questions.length;

    return Column(
      children: [
        _ProgressStrip(value: progress),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Question ${_q + 1} of ${questions.length}',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                question.question,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < question.options.length; i++) ...[
                _OptionTile(
                  label: question.options[i],
                  state: _optionState(i, question.answerIndex),
                  onTap: answered ? null : () => _pick(i),
                ),
                const SizedBox(height: 10),
              ],
              if (answered) ...[
                const SizedBox(height: 8),
                Text(
                  isRight
                      ? 'Correct!'
                      : 'Not quite. The answer is '
                          '"${question.options[question.answerIndex]}".',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isRight ? Palette.olive : Palette.tomato,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: BigButton(
            label: 'Continue',
            onPressed: answered ? _nextQuestion : null,
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final r = _reward;
    if (r == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final total = widget.story.questions.length;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.story.emoji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 72),
          ),
          const SizedBox(height: 16),
          Text(
            'Story complete',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$_correct of $total answers correct',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          _RewardLine(text: '+${r.xp} XP', color: Palette.lemonDark, glyph: Glyph.xp),
          const SizedBox(height: 10),
          _RewardLine(text: '+${r.gems}', color: Palette.gem, glyph: Glyph.gem),
          const SizedBox(height: 10),
          _RewardLine(text: '${r.streak} day streak', color: Palette.tomato, glyph: Glyph.streak),
          const SizedBox(height: 32),
          BigButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ProgressBar(value: value),
    );
  }
}

/// One dialogue line as a chat bubble. The English text is hidden until tapped.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.line,
    required this.alignLeft,
    required this.translated,
    required this.onReveal,
    required this.onSpeak,
  });

  final StoryLine line;
  final bool alignLeft;
  final bool translated;
  final VoidCallback onReveal;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = alignLeft
        ? (theme.cardTheme.color ?? Colors.white)
        : Palette.teal;
    final fg = alignLeft ? theme.colorScheme.onSurface : Colors.white;
    final muted = alignLeft
        ? theme.colorScheme.onSurfaceVariant
        : Colors.white.withValues(alpha: 0.85);
    final radius = Radius.circular(18);

    return Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              bottomLeft: Radius.circular(alignLeft ? 4 : 18),
              bottomRight: Radius.circular(alignLeft ? 18 : 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.speaker,
                style: theme.textTheme.labelMedium?.copyWith(color: muted),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        line.it,
                        style: TextStyle(
                          color: fg,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: fg),
                    tooltip: 'Listen to this line',
                    onPressed: onSpeak,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (translated)
                Text(
                  line.en,
                  style: TextStyle(color: muted, fontSize: 16),
                )
              else
                Semantics(
                  button: true,
                  label: 'Show English translation',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onReveal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Tap to see English',
                        style: TextStyle(
                          color: muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = theme.cardTheme.color ?? Colors.white;
    final Color bg;
    final Color fg;
    final IconData? icon;
    final Color border;
    switch (state) {
      case _OptionState.idle:
        bg = card;
        fg = theme.colorScheme.onSurface;
        icon = null;
        border = Palette.mist;
      case _OptionState.correct:
        bg = Palette.olive;
        fg = Colors.white;
        icon = Icons.check_circle;
        border = Palette.olive;
      case _OptionState.wrong:
        bg = Palette.tomato;
        fg = Colors.white;
        icon = Icons.cancel;
        border = Palette.tomato;
      case _OptionState.dimmed:
        bg = card;
        fg = theme.colorScheme.onSurface.withValues(alpha: 0.45);
        icon = null;
        border = Palette.mist;
    }
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border, width: 2),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.text, required this.color, required this.glyph});

  final String text;
  final Color color;
  final Glyph glyph;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlyphIcon(glyph, size: 34),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
