import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/symbols.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/course.dart';
import '../../domain/dates.dart';
import '../../domain/levels.dart';
import '../../domain/quests.dart';
import '../../state/app_state.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';
import '../settings/settings_screen.dart';
import 'streak_calendar.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final now = ref.watch(clockProvider)();
    final ctrl = ref.read(appProvider.notifier);
    final theme = Theme.of(context);

    final today = dayKey(now);
    final weekStart = parseDayKey(weekKey(now));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekXp = [for (final d in days) s.xpOn(dayKey(d))];
    final todayIndex = days.indexWhere((d) => dayKey(d) == today);

    final stats = [
      _Stat(glyph: Glyph.streak, value: s.streakAt(now), label: 'Day streak'),
      _Stat(glyph: Glyph.medal, value: s.longestStreak, label: 'Longest streak'),
      _Stat(glyph: Glyph.xp, value: s.xp, label: 'Total XP'),
      _Stat(
        glyph: Glyph.trophy,
        value: s.completedLessons.length,
        label: 'Lessons done',
      ),
      _Stat(glyph: Glyph.book, value: s.wordsLearned, label: 'Words learned'),
      _Stat(glyph: Glyph.star, value: s.perfectLessons, label: 'Perfect lessons'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Semantics(
                  label: 'Profile picture, initial ${_initialOf(s.name)}',
                  child: ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Palette.teal,
                      child: Text(
                        _initialOf(s.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Learning ${ref.watch(courseProvider).language.name}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Palette.ink),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 180,
                  child: BigButton.secondary(
                    label: 'Rename',
                    icon: Icons.edit_rounded,
                    onPressed: () => _rename(context, s.name, ctrl),
                  ),
                ),
              ],
            ),
            SectionTitle('Your ${ref.watch(courseProvider).language.name} level'),
            _LevelsCard(state: s),
            const SectionTitle('Your stats'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [for (final stat in stats) _StatTile(stat: stat)],
            ),
            const SectionTitle('This week, XP per day'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                child: _WeekChart(
                  values: weekXp,
                  goal: s.dailyGoalXp,
                  todayIndex: todayIndex,
                ),
              ),
            ),
            const SectionTitle('Streak calendar'),
            StreakCalendar(state: s, now: now),
            const SectionTitle('Achievements'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.achievements.length} of ${achievementDefs.length} unlocked',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final a in achievementDefs)
                          _AchievementBadge(
                            def: a,
                            unlocked: s.achievements.contains(a.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

String _initialOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

Future<void> _rename(
  BuildContext context,
  String current,
  AppController ctrl,
) async {
  final next = await showDialog<String>(
    context: context,
    builder: (_) => _RenameDialog(initial: current),
  );
  if (next != null) ctrl.setName(next);
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _Stat {
  const _Stat({required this.glyph, required this.value, required this.label});

  final Glyph glyph;
  final int value;
  final String label;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '${stat.label}: ${stat.value}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlyphIcon(stat.glyph, size: 30),
              Text(
                '${stat.value}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                stat.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({
    required this.values,
    required this.goal,
    required this.todayIndex,
  });

  final List<int> values;
  final int goal;
  final int todayIndex;

  static const _barArea = 120.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = values.fold<int>(goal, (m, v) => v > m ? v : m);
    final scale = _barArea / (top == 0 ? 1 : top);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'Weekly XP chart. Today ${values[todayIndex]} XP. Daily goal $goal XP.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _barArea,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < values.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(
                              height: values[i] * scale,
                              decoration: BoxDecoration(
                                color: i == todayIndex
                                    ? Palette.tomato
                                    : Palette.teal.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: goal * scale - 1,
                  child: Container(height: 2, color: Palette.lemonDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < _weekdayLabels.length; i++)
                Expanded(
                  child: Text(
                    _weekdayLabels[i],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight:
                          i == todayIndex ? FontWeight.w900 : FontWeight.w600,
                      color: i == todayIndex ? Palette.tomato : Palette.ink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 14, height: 2, color: Palette.lemonDark),
              const SizedBox(width: 6),
              Text(
                'Daily goal: $goal XP',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.def, required this.unlocked});

  final AchievementDef def;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${def.title}, ${unlocked ? 'unlocked' : 'locked'}. ${def.description}',
      child: Opacity(
        opacity: unlocked ? 1 : 0.25,
        child: Text(def.emoji, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}

/// One row per CEFR level: passed, in progress or still locked.
class _LevelsCard extends ConsumerWidget {
  const _LevelsCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final current = course.currentLevel(state.completedLessons, state.passedLevels);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final level in course.levels)
              _row(context, course, level, level.id == current),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Course course, CefrLevel level, bool isCurrent) {
    final total = course.lessonsOfLevel(level.id).length;
    final done = course.doneIn(level.id, state.completedLessons);
    final passed = state.passedLevels.contains(level.id);
    final best = state.checkpointBest[level.id];
    final String status;
    if (passed) {
      status = 'Passed${best == null ? '' : ', best $best%'}';
    } else if (done == total) {
      status = 'Checkpoint ready${best == null ? '' : ', best $best%'}';
    } else if (done > 0 || isCurrent) {
      status = '$done of $total lessons';
    } else {
      status = 'Locked';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(level.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${level.id}  ${level.name}',
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                Text(status, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
              ],
            ),
          ),
          if (passed)
            const GlyphIcon(Glyph.correct, size: 26)
          else if (isCurrent)
            const Icon(Icons.play_circle_fill_rounded, color: Palette.teal),
        ],
      ),
    );
  }
}
