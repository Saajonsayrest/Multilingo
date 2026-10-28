import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/speech.dart' show speechProvider;
import '../../core/theme.dart';
import '../../state/course_state.dart';
import '../../domain/models.dart';

/// Shows how Italian letters are read, with one example word per sound.
class AlphabetScreen extends ConsumerWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(courseProvider).alphabet;
    return Scaffold(
      appBar: AppBar(title: const Text('Sounds and Letters')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How ${ref.watch(courseProvider).language.name} sounds are written',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each letter, or group of letters, has a main sound. '
                    'Learn these sounds once and you can say most '
                    '${ref.watch(courseProvider).language.name} words, '
                    'even new ones you have never seen.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in entries) ...[
            _SoundCard(
              entry: entry,
              onSpeak: () => ref.read(speechProvider).speak(entry.example),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.entry, required this.onSpeak});

  final AlphabetEntry entry;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                entry.symbol,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Palette.teal,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.sound,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.example,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    entry.exampleEn,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: 'Listen to ${entry.example}',
              onPressed: onSpeak,
            ),
          ],
        ),
      ),
    );
  }
}
