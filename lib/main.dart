import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/account_screen.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'state/auth_gateway.dart';
import 'state/cloud_store.dart';
import 'state/cloud_sync.dart';
import 'state/controller.dart';
import 'state/reminder_service.dart';
import 'state/widget_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final cloud = await _startFirebase();
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        if (cloud) ...[
          authGatewayProvider.overrideWithValue(FirebaseAuthGateway()),
          cloudStoreProvider.overrideWithValue(FirestoreCloudStore()),
        ],
      ],
      child: const MultilingoApp(),
    ),
  );
}

/// Starts Firebase. It needs no connection. If it cannot start (for example
/// on a platform without a config) the app still works, on this phone only.
Future<bool> _startFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return true;
  } catch (_) {
    return false;
  }
}

class MultilingoApp extends ConsumerWidget {
  const MultilingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    // Starts the cloud sync and keeps it alive without rebuilding the app on
    // every status change.
    ref.listen(cloudSyncProvider, (_, _) {});
    ref.listen(appProvider, (before, after) {
      ref.read(cloudSyncProvider.notifier).onStateChanged(before, after);
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
      home: ConflictHost(
        child: s.onboarded ? const HomeShell() : const OnboardingScreen(),
      ),
    );
  }
}
