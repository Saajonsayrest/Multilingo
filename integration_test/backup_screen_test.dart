import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:multilingo/main.dart';
import 'package:multilingo/state/backup_service.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens Settings, then Backup and restore, on a real device or simulator,
/// and creates one restore point and the single backup file.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('backup screen on device', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
    c.read(appProvider.notifier).completeOnboarding(
        name: 'Sajon', dailyGoalXp: 20, level: 'beginner');
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const MultilingoApp()));
    await t.pump(const Duration(seconds: 1));

    await t.tap(find.byIcon(Icons.person_rounded).last);
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.byIcon(Icons.settings_rounded).first);
    await t.pump(const Duration(seconds: 2));
    await t.scrollUntilVisible(find.text('Backup and restore'), 300,
        scrollable: find.byType(Scrollable).first);
    await t.pump(const Duration(seconds: 3)); // screenshot: settings tile
    await t.tap(find.text('Backup and restore'));
    await t.pump(const Duration(seconds: 3));

    // Real file write on the device: exactly one file must exist.
    final file = await c.read(backupServiceProvider).writeRolling();
    await c.read(backupServiceProvider).writeRolling();
    expect(await file.exists(), isTrue);
    expect(file.path.endsWith('duolingo-backup.json'), isTrue);
    final siblings = file.parent.listSync().where((e) => e.path.contains('duolingo-backup'));
    expect(siblings.length, 1);
    await t.pump(const Duration(seconds: 3)); // screenshot: backup screen

    await t.tap(find.text('CREATE A RESTORE POINT'));
    await t.pump(const Duration(seconds: 1));
    await t.enterText(find.byType(TextField), 'Before exam');
    await t.tap(find.text('Save'));
    await t.pump(const Duration(seconds: 3)); // screenshot: restore point
    expect(find.text('Before exam'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
    c.dispose();
  });
}
