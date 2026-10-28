import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/symbols.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/exercise_generator.dart';
import '../../domain/levels.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';
import '../lesson/lesson_screen.dart';
import '../shop/shop_screen.dart';

final generatorProvider = Provider<ExerciseGenerator>(
  (ref) => ExerciseGenerator(allWords: ref.watch(courseProvider).allWords),
);

/// The learning path: units as colour banners, lessons as round nodes.
class PathScreen extends ConsumerWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final course = ref.watch(courseProvider);
    final current = course.flatLessons[course.currentIndex(s.completedLessons)];
    // 220+ lessons: keep a list of cheap builders and let the list create
    // only the rows that are on screen.
    final items = <Widget Function()>[];
    var node = 0;
    for (final level in course.levels) {
      items.add(() => _LevelHeader(level: level, state: s));
      for (final unit in course.unitsOfLevel(level.id)) {
        items.add(() => _UnitBanner(unit: unit));
        for (final lesson in unit.lessons) {
          final index = node++;
          items.add(() {
            final done = s.completedLessons.contains(lesson.id);
            final unlocked =
                course.isUnlocked(lesson.id, s.completedLessons, s.passedLevels);
            return _LessonNode(
              key: ValueKey(lesson.id),
              lesson: lesson,
              unit: unit,
              offset: sin(index * 0.9) * 62,
              done: done,
              current: lesson.id == current.id && !done && unlocked,
              locked: !unlocked,
              runs: s.lessonRuns[lesson.id] ?? 0,
            );
          });
        }
        items.add(() => const SizedBox(height: 12));
      }
      items.add(() => _CheckpointCard(level: level, state: s));
      items.add(() => const SizedBox(height: 12));
    }
    return ListView.builder(
      // A new key per language, so the list starts at the top again.
      key: ValueKey(course.language.id),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i](),
    );
  }
}

/// Big banner that opens each CEFR level, with progress.
class _LevelHeader extends ConsumerWidget {
  const _LevelHeader({required this.level, required this.state});

  final CefrLevel level;
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final lessons = course.lessonsOfLevel(level.id).length;
    final done = course.doneIn(level.id, state.completedLessons);
    final passed = state.passedLevels.contains(level.id);
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(level.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${level.id}  ${level.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (passed)
                const GlyphIcon(Glyph.badge, size: 32),
            ],
          ),
          const SizedBox(height: 6),
          Text(level.blurb, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ProgressBar(
            value: lessons == 0 ? 0 : done / lessons,
            color: Palette.lemon,
            height: 10,
          ),
          const SizedBox(height: 4),
          Text(
            '$done of $lessons lessons',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// The level test: unlocks after the last lesson, opens the next level.
class _CheckpointCard extends ConsumerWidget {
  const _CheckpointCard({required this.level, required this.state});

  final CefrLevel level;
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final ready = course.checkpointReady(level.id, state.completedLessons);
    final passed = state.passedLevels.contains(level.id);
    final best = state.checkpointBest[level.id];
    final isLast = course.levels.last.id == level.id;
    final next = isLast ? null : course.levels[course.levels.indexWhere((l) => l.id == level.id) + 1];
    final color = passed ? Palette.olive : (ready ? Palette.tomato : const Color(0xFFCFC8B8));
    final String status;
    if (passed) {
      status = 'Passed${best == null ? '' : ' with $best%'}';
    } else if (ready) {
      status = best == null
          ? 'Ready. Score ${(checkpointPassMark * 100).round()}% to pass.'
          : 'Best so far: $best%. Score ${(checkpointPassMark * 100).round()}% to pass.';
    } else {
      status = 'Finish all ${level.id} lessons to unlock.';
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 3),
        color: color.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                passed ? Icons.emoji_events_rounded : (ready ? Icons.flag_rounded : Icons.lock_rounded),
                color: color,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${level.id} Checkpoint',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    Text(status),
                  ],
                ),
              ),
            ],
          ),
          if (next != null && !passed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Passing opens ${next.id} ${next.name}.',
                style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
              ),
            ),
          if (ready) ...[
            const SizedBox(height: 12),
            BigButton(
              label: passed ? 'Take it again' : 'Start checkpoint',
              color: passed ? Palette.olive : Palette.tomato,
              shadow: passed ? Palette.oliveDark : Palette.tomatoDark,
              onPressed: () {
                final exercises = ref.read(generatorProvider).forCheckpoint(
                      course.lessonsOfLevel(level.id),
                      count: checkpointQuestions,
                    );
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => LessonScreen(
                      title: '${level.id} Checkpoint',
                      exercises: exercises,
                      kind: SessionKind.checkpoint,
                      levelId: level.id,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.unit});

  final UnitDef unit;

  @override
  Widget build(BuildContext context) {
    final color = Color(unit.colorValue);
    return Container(
      margin: const EdgeInsets.only(top: 18, bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(unit.subtitle,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Unit guide',
            icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => _GuideSheet(unit: unit),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSheet extends StatelessWidget {
  const _GuideSheet({required this.unit});

  final UnitDef unit;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guide: ${unit.title}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              for (final tip in unit.guide)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡 '),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}

class _LessonNode extends ConsumerStatefulWidget {
  const _LessonNode({
    super.key,
    required this.lesson,
    required this.unit,
    required this.offset,
    required this.done,
    required this.current,
    required this.locked,
    required this.runs,
  });

  final LessonDef lesson;
  final UnitDef unit;
  final double offset;
  final bool done;
  final bool current;
  final bool locked;
  final int runs;

  @override
  ConsumerState<_LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends ConsumerState<_LessonNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.current) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LessonNode old) {
    super.didUpdateWidget(old);
    if (widget.current && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.current && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _open() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StartSheet(lesson: widget.lesson, unit: widget.unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.unit.colorValue);
    final base = widget.locked ? const Color(0xFFCFC8B8) : color;
    final label = widget.locked
        ? 'Locked: ${widget.lesson.title}'
        : widget.done
            ? 'Completed: ${widget.lesson.title}'
            : 'Start: ${widget.lesson.title}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Transform.translate(
        offset: Offset(widget.offset, 0),
        child: Center(
          child: Column(
            children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.08).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: Semantics(
                  button: true,
                  label: label,
                  child: GestureDetector(
                    onTap: widget.locked ? null : _open,
                    child: Container(
                      width: 78,
                      height: 72,
                      decoration: BoxDecoration(
                        color: base,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.lerp(base, Colors.black, 0.25)!,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.locked
                            ? Icons.lock_rounded
                            : widget.done
                                ? Icons.check_rounded
                                : Icons.star_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.lesson.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: widget.locked ? Colors.grey : null,
                ),
              ),
              if (widget.runs > 1)
                Text('Practiced ${widget.runs}x',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartSheet extends ConsumerWidget {
  const _StartSheet({required this.lesson, required this.unit});

  final LessonDef lesson;
  final UnitDef unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final now = ref.watch(clockProvider)();
    final hearts = s.heartsAt(now);
    final wait = s.nextHeartIn(now);
    final color = Color(unit.colorValue);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(lesson.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${lesson.words.length} new words, ${lesson.sentences.length} sentences'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final w in lesson.words)
                  Chip(
                    avatar: w.emoji == null ? null : Text(w.emoji!),
                    label: Text(w.it),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (unit.lessons.first.id == lesson.id && unit.guide.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Before you start',
                        style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    for (final tip in unit.guide)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('💡 $tip', style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (hearts == 0) ...[
              Text(
                'No hearts left.${wait == null ? '' : ' Next one in ${_fmt(wait)}.'}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              BigButton(
                label: 'Refill for $heartRefillGems',
                glyph: Glyph.gem,
                onPressed: s.gems >= heartRefillGems
                    ? () {
                        ref.read(appProvider.notifier).refillHeartsWithGems();
                      }
                    : null,
                color: Palette.gem,
                shadow: const Color(0xFF5942CC),
              ),
              const SizedBox(height: 8),
              BigButton.secondary(
                label: 'Visit the shop',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
                  );
                },
              ),
            ] else
              BigButton(
                label: 'Start  +10 XP',
                color: color,
                shadow: Color.lerp(color, Colors.black, 0.25)!,
                onPressed: () {
                  final weak = s.mistakes;
                  final exercises = ref
                      .read(generatorProvider)
                      .forLesson(lesson, weakWordIds: weak);
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => LessonScreen(
                        title: lesson.title,
                        exercises: exercises,
                        lessonId: lesson.id,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
