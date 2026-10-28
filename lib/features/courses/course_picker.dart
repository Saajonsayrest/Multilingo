import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/course.dart';
import '../../data/languages.dart';
import '../../state/app_state.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';

/// The "I want to learn..." sheet, opened from the flag on the home screen.
/// Each language keeps its own lessons, review words and level results.
Future<void> showCoursePicker(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _CoursePicker(),
    );

class _CoursePicker extends ConsumerWidget {
  const _CoursePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeCourseProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'I want to learn...',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final lang in languages) ...[
              _CourseTile(
                language: lang,
                selected: lang.id == active,
                lessonsDone: _lessonsDone(ref, lang),
                onTap: () {
                  ref.read(appProvider.notifier).switchCourse(lang.id);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  /// Lessons finished in [lang]. The active course is in the main state, the
  /// others in the stash.
  int _lessonsDone(WidgetRef ref, Language lang) {
    if (lang.id == ref.read(activeCourseProvider)) {
      return ref.read(appProvider).completedLessons.length;
    }
    final saved = readStash(ref.read(prefsProvider))[lang.id];
    if (saved == null) return 0;
    try {
      return AppState.fromJson(saved).completedLessons.length;
    } catch (_) {
      return 0;
    }
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.language,
    required this.selected,
    required this.lessonsDone,
    required this.onTap,
  });

  final Language language;
  final bool selected;
  final int lessonsDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = Course.of(language.id).flatLessons.length;
    return Material(
      color: selected ? scheme.primary.withValues(alpha: 0.12) : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Text('$lessonsDone of $total lessons done'),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
