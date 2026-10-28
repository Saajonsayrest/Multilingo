import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/backup.dart';
import 'package:multilingo/features/settings/backup_screen.dart';
import 'package:multilingo/l10n/app_localizations.dart';
import 'package:multilingo/state/app_state.dart';
import 'package:multilingo/state/backup_files.dart';
import 'package:multilingo/state/backup_service.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeFiles implements BackupFiles {
  String? pickResult;
  Uint8List? saved;
  File? shared;

  @override
  Future<String?> pickText() async => pickResult;

  @override
  Future<bool> saveAs(Uint8List bytes) async {
    saved = bytes;
    return true;
  }

  @override
  Future<void> share(File file, {Rect? origin}) async => shared = file;
}

String backupText(int xp) => BackupEnvelope.fromStates(
      id: 'b1',
      createdAt: DateTime.utc(2026, 3, 2, 10),
      label: 'Phone',
      kind: BackupKind.manual,
      appVersion: '0.1.0',
      states: {'it': (AppState()..xp = xp).toJson()},
    ).encode();

void main() {
  late FakeFiles files;
  late ProviderContainer container;
  final disposed = <ProviderContainer>{};

  /// Ends the screen and cancels the auto-save timer a restore starts, so the
  /// test framework sees no pending timers.
  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    disposed.add(container);
    container.dispose();
  }

  Future<void> pump(WidgetTester t, {Locale locale = const Locale('en')}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dir = await t.runAsync(() => Directory.systemTemp.createTemp('multilingo_ui'));
    addTearDown(() => dir!.delete(recursive: true));
    files = FakeFiles();
    container = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      backupDirProvider.overrideWithValue(Future.value(dir)),
      backupFilesProvider.overrideWithValue(files),
    ]);
    final mine = container;
    addTearDown(() {
      if (!disposed.contains(mine)) mine.dispose();
    });
    // A tall screen, so popup menus and lists are not clipped.
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    container.read(appProvider.notifier).completeOnboarding(
        name: 'T', dailyGoalXp: 20, level: 'beginner');
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupScreen(),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump();
  }

  /// Real file work and fake-clock widget work take turns, so alternate a few
  /// times until chained awaits (write, read, dialog) have all finished.
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 30; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('screen is translated (English, Italian, Spanish)', (t) async {
    await pump(t);
    expect(find.text('Backup and restore'), findsOneWidget);
    await pump(t, locale: const Locale('it'));
    expect(find.text('Backup e ripristino'), findsOneWidget);
    await pump(t, locale: const Locale('es'));
    expect(find.text('Copia de seguridad y restauración'), findsOneWidget);
  });

  testWidgets('shows the one fixed file name', (t) async {
    await pump(t);
    expect(find.text('File name: duolingo-backup.json'), findsOneWidget);
  });

  testWidgets('import asks first, then restores', (t) async {
    await pump(t);
    files.pickResult = backupText(321);
    await t.ensureVisible(find.text('RESTORE FROM A FILE'));
    await t.tap(find.text('RESTORE FROM A FILE'));
    await settle(t);
    expect(find.text('Restore this backup?'), findsOneWidget);
    expect(container.read(appProvider).xp, 0); // nothing changed yet
    await t.tap(find.text('Restore').last);
    await settle(t);
    expect(container.read(appProvider).xp, 321);
    expect(find.text('Progress restored.'), findsOneWidget);
    await done(t);
  });

  testWidgets('cancelling the confirm dialog changes nothing', (t) async {
    await pump(t);
    files.pickResult = backupText(321);
    await t.ensureVisible(find.text('RESTORE FROM A FILE'));
    await t.tap(find.text('RESTORE FROM A FILE'));
    await settle(t);
    await t.tap(find.text('Cancel'));
    await settle(t);
    expect(container.read(appProvider).xp, 0);
  });

  testWidgets('a bad file shows a clear message and changes nothing', (t) async {
    await pump(t);
    files.pickResult = '{"hello": 1}';
    await t.ensureVisible(find.text('RESTORE FROM A FILE'));
    await t.tap(find.text('RESTORE FROM A FILE'));
    await settle(t);
    expect(find.text('This is not a Multilingo backup file.'), findsOneWidget);
    expect(container.read(appProvider).xp, 0);
  });

  testWidgets('save writes the single file and hands bytes to the dialog', (t) async {
    await pump(t);
    await t.tap(find.text('SAVE BACKUP FILE'));
    await settle(t);
    expect(files.saved, isNotNull);
    final env = BackupEnvelope.decode(String.fromCharCodes(files.saved!));
    expect(env.courses.containsKey('it'), isTrue);
    expect(find.text('Backup saved.'), findsOneWidget);
  });

  testWidgets('restore points: create, then delete', (t) async {
    await pump(t);
    await t.ensureVisible(find.text('CREATE A RESTORE POINT'));
    await t.tap(find.text('CREATE A RESTORE POINT'));
    await t.pump(const Duration(milliseconds: 400));
    await t.enterText(find.byType(TextField), 'Before exam');
    await t.tap(find.text('Save'));
    await settle(t);
    expect(find.text('Before exam'), findsOneWidget);
    // The popup is exercised by calling its callback: opening it in a test
    // depends on overlay animation timing, not on our code.
    t.widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
        .onSelected!('delete');
    await settle(t);
    expect(find.text('Before exam'), findsNothing);
    expect(find.text('No restore points yet.'), findsOneWidget);
  });
}
