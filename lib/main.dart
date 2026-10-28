import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/app_localizations.dart';
import 'state/backup_service.dart';
import 'state/controller.dart';
import 'state/reminder_service.dart';
import 'state/widget_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const MultilingoApp(),
    ),
  );
}

class MultilingoApp extends ConsumerWidget {
  const MultilingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    // Keep the single backup file fresh after every change.
    ref.listen(appProvider, (before, after) {
      final backup = ref.read(backupServiceProvider);
      backup.scheduleAutoSave();
      backup.noteChange(before, after);
      ref.read(widgetSyncProvider).schedule();
      // Practising today, a new streak or a new time changes the reminders.
      ref.read(reminderServiceProvider).schedule();
    });
    return MaterialApp(
      title: 'Multilingo',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (s.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: s.onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
