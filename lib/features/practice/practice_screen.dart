import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mascot.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';
import '../alphabet/alphabet_screen.dart';
import '../lesson/lesson_screen.dart';
import '../path/path_screen.dart';
import '../shop/shop_screen.dart';
import '../stories/stories_screen.dart';

/// Review hub: spaced repetition, mistakes, plus entry to stories, sounds
/// and the shop.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final now = ref.watch(clockProvider)();
    final course = ref.watch(courseProvider);
    final due = s.dueWordIds(now).map(course.word).whereType<Word>().toList();
    final wrong = s.mistakes.map(course.word).whereType<Word>().toList();
    final learned = s.wordBox.keys.map(course.word).whereType<Word>().toList();

    void run(String title, List<Word> words, {int count = 10}) {
      final ex = ref.read(generatorProvider).forWords(words, count: count);
      if (ex.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => LessonScreen(
            title: title,
            exercises: ex,
            kind: SessionKind.practice,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(
          title: 'Smart review',
          body: due.isEmpty
              ? 'Nothing is due. Finish a lesson to add words to your review.'
              : '${due.length} words are ready to review. Reviewing at the right moment makes them stick.',
          mood: due.isEmpty ? MascotMood.sleeping : MascotMood.encouraging,
          button: 'Review ${due.length} words',
          onPressed: due.isEmpty ? null : () => run('Smart review', due),
        ),
        const SizedBox(height: 14),
        _HeroCard(
          title: 'Fix my mistakes',
          body: wrong.isEmpty
              ? 'No mistakes to fix. Nice work!'
              : '${wrong.length} words gave you trouble. Practice them now and win a heart.',
          mood: wrong.isEmpty ? MascotMood.proud : MascotMood.reassured,
          button: 'Practice mistakes',
          color: Palette.tomato,
          shadow: Palette.tomatoDark,
          onPressed: wrong.isEmpty ? null : () => run('Mistakes', wrong),
        ),
        const SectionTitle('Explore'),
        _Tile(
          emoji: '🎭',
          title: 'Stories',
          subtitle: 'Read and listen to short conversations',
          onTap: () => _push(context, const StoriesScreen()),
        ),
        const SizedBox(height: 10),
        _Tile(
          emoji: '🔤',
          title: 'Sounds and letters',
          subtitle: 'How ${course.language.name} is pronounced',
          onTap: () => _push(context, const AlphabetScreen()),
        ),
        const SizedBox(height: 10),
        _Tile(
          emoji: '🛍️',
          title: 'Shop',
          subtitle: 'Hearts, streak freezes and XP boosts',
          onTap: () => _push(context, const ShopScreen()),
        ),
        const SizedBox(height: 10),
        _Tile(
          emoji: '🧠',
          title: 'Word workout',
          subtitle: learned.length < 4
              ? 'Learn at least 4 words to unlock'
              : 'Random drill of ${learned.length} words you know',
          onTap: learned.length < 4
              ? null
              : () => run('Word workout', learned, count: 12),
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
    required this.mood,
    this.color = Palette.teal,
    this.shadow = Palette.tealDark,
  });

  final String title;
  final String body;
  final String button;
  final VoidCallback? onPressed;
  final MascotMood mood;
  final Color color;
  final Color shadow;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Mascot(mood: mood, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(body),
              const SizedBox(height: 14),
              BigButton(
                label: button,
                onPressed: onPressed,
                color: color,
                shadow: shadow,
              ),
            ],
          ),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Card(
          child: ListTile(
            onTap: onTap,
            leading: Text(emoji, style: const TextStyle(fontSize: 30)),
            title:
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      );
}
