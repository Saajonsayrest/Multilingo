import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/status.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_sync.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';
import '../../state/reminder_service.dart';
import 'account_screen.dart';

const _dailyGoals = [10, 20, 30, 50];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final ctrl = ref.read(appProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Sound and feel'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sound'),
                  subtitle: const Text('Play sounds in lessons'),
                  value: s.soundOn,
                  onChanged: ctrl.setSound,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Haptics'),
                  subtitle: const Text('Small vibrations on taps'),
                  value: s.hapticsOn,
                  onChanged: ctrl.setHaptics,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Speech'),
                  subtitle: Text(
                    'Read ${ref.watch(courseProvider).language.name} words out loud',
                  ),
                  value: s.speechOn,
                  onChanged: ctrl.setSpeech,
                ),
              ],
            ),
          ),
          const SectionTitle('Reminder'),
          const _ReminderCard(),
          const SectionTitle('Daily goal'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'XP to earn each day',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<int>(
                    segments: [
                      for (final goal in _dailyGoals)
                        ButtonSegment<int>(
                          value: goal,
                          label: Text('$goal XP'),
                        ),
                    ],
                    selected: {s.dailyGoalXp},
                    onSelectionChanged: (selection) =>
                        ctrl.setDailyGoal(selection.first),
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('Theme'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Light, dark, or follow the phone',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'system',
                        label: Text('System'),
                      ),
                      ButtonSegment<String>(
                        value: 'light',
                        label: Text('Light'),
                      ),
                      ButtonSegment<String>(
                        value: 'dark',
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (selection) =>
                        ctrl.setThemeMode(selection.first),
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('Your data'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_upload_rounded, color: Palette.teal),
              title: Text(
                AppLocalizations.of(context).accountTitle,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(AppLocalizations.of(context).accountTileSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              ),
            ),
          ),
          const SectionTitle('Danger zone'),
          BigButton(
            label: 'Reset all progress',
            color: Palette.tomato,
            shadow: Palette.tomatoDark,
            onPressed: () => _confirmReset(context, ref),
          ),
          const SizedBox(height: 28),
          const _VersionFooter(),
        ],
      ),
    );
  }
}

/// Daily reminder: a switch and the time of day. Turning it on asks the phone
/// for permission to show notifications.
class _ReminderCard extends ConsumerWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final time = TimeOfDay(hour: s.reminderMinutes ~/ 60, minute: s.reminderMinutes % 60);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Daily reminder'),
            subtitle: const Text('A nudge to practise, only on days you have not yet'),
            value: s.reminderOn,
            onChanged: (on) async {
              final service = ref.read(reminderServiceProvider);
              if (!on) {
                await service.disable();
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              final granted = await service.enable();
              if (!granted) {
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text(
                      'Notifications are blocked. Turn them on for Multilingo in your phone settings.',
                    ),
                  ));
              }
            },
          ),
          if (s.reminderOn) ...[
            const Divider(height: 1),
            ListTile(
              title: const Text('Reminder time'),
              trailing: Text(
                time.format(context),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: time);
                if (picked == null) return;
                ref.read(appProvider.notifier).setReminderTime(picked.hour * 60 + picked.minute);
                await ref.read(reminderServiceProvider).sync();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// The version line. Tapping it [_secretTaps] times in a row refills all hearts.
const _secretTaps = 7;

class _VersionFooter extends ConsumerStatefulWidget {
  const _VersionFooter();

  @override
  ConsumerState<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends ConsumerState<_VersionFooter> {
  int _taps = 0;

  void _tap() {
    _taps++;
    if (_taps < _secretTaps) return;
    _taps = 0;
    ref.read(appProvider.notifier).refillHearts();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Hearts refilled')));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'Multilingo 1.0 - an original language learning app',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
  final navigator = Navigator.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reset all progress?'),
      content: const Text(
        'Your XP, streak, gems, lessons and achievements will be deleted. '
        'A restore point is saved first, so you can undo this in Account and cloud save.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Palette.tomato),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  // The undo point lives in the cloud. Without it the reset could not be
  // undone, so a failed save stops the reset. With no account there is
  // nothing in the cloud to protect.
  try {
    await ref.read(cloudSyncProvider.notifier).checkpointBeforeReset();
  } catch (_) {
    if (context.mounted) {
      showToast(context, AppLocalizations.of(context).resetNeedsOnline,
          kind: StatusKind.error);
    }
    return;
  }
  ref.read(appProvider.notifier).resetAll();
  navigator.popUntil((route) => route.isFirst);
}
