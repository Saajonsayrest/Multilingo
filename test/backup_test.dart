import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/backup.dart';
import 'package:multilingo/state/app_state.dart';
import 'package:multilingo/state/backup_service.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [states] are whole app states, one per course.
BackupEnvelope envelope({Map<String, Map<String, dynamic>>? states, String label = 'x'}) =>
    BackupEnvelope.fromStates(
      id: 'id1',
      createdAt: DateTime.utc(2026, 3, 2, 10),
      label: label,
      kind: BackupKind.manual,
      appVersion: '0.1.0',
      states: states ?? {'it': (AppState()..xp = 42).toJson()},
    );

BackupError? errorOf(String raw) {
  try {
    BackupEnvelope.decode(raw);
    return null;
  } on BackupException catch (e) {
    return e.error;
  }
}

Future<(ProviderContainer, Directory)> boot() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final dir = await Directory.systemTemp.createTemp('multilingo_backup_test');
  addTearDown(() => dir.delete(recursive: true));
  var tick = 0;
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    backupDirProvider.overrideWithValue(Future.value(dir)),
    // Each call is one minute later, so checkpoints have distinct times.
    clockProvider.overrideWithValue(
      () => DateTime(2026, 3, 2, 10).add(Duration(minutes: tick++)),
    ),
  ]);
  addTearDown(c.dispose);
  c.read(appProvider.notifier).completeOnboarding(
      name: 'Sajon', dailyGoalXp: 20, level: 'beginner');
  return (c, dir);
}

void main() {
  group('format', () {
    test('round trip keeps everything', () {
      final back = BackupEnvelope.decode(envelope(label: 'My label').encode());
      expect(back.label, 'My label');
      expect(back.kind, BackupKind.manual);
      expect(back.stateFor('it')['xp'], 42);
      expect(back.createdAt.toUtc(), DateTime.utc(2026, 3, 2, 10));
    });

    test('file name is fixed', () {
      expect(backupFileName, 'duolingo-backup.json');
    });

    test('schema 1 (bare state) is upgraded', () {
      final legacy = jsonEncode((AppState()..xp = 7).toJson());
      final env = BackupEnvelope.decode(legacy);
      expect(env.courses.keys, ['it']);
      expect(env.stateFor('it')['xp'], 7);
    });

    test('schema 2 (whole state per course) is split and upgraded', () {
      final state = (AppState()
            ..xp = 9
            ..gems = 123
            ..completedLessons = {'u1l1'})
          .toJson();
      final courses = {'it': state};
      final v2 = jsonEncode({
        'app': 'multilingo',
        'schema': 2,
        'id': 'old',
        'createdAt': '2026-03-02T10:00:00.000Z',
        'label': 'old',
        'kind': 'manual',
        'appVersion': '0.1.0',
        'checksum': checksumOf(courses),
        'courses': courses,
      });
      final env = BackupEnvelope.decode(v2);
      expect(env.activeCourse, 'it');
      expect(env.profile['gems'], 123);
      expect(env.profile.containsKey('completedLessons'), isFalse);
      expect(env.courses['it']!.containsKey('gems'), isFalse);
      expect(env.courses['it']!['completedLessons'], ['u1l1']);
      expect(env.stateFor('it')['xp'], 9);
      // Saving it again writes schema 3 and still decodes.
      expect(BackupEnvelope.decode(env.encode()).stateFor('it')['gems'], 123);
    });

    test('profile is shared and each language keeps its own lessons', () {
      final it = (AppState()
            ..gems = 80
            ..completedLessons = {'it1'})
          .toJson();
      final es = (AppState()..completedLessons = {'es1', 'es2'}).toJson();
      final env = BackupEnvelope.decode(
        envelope(states: {'it': it, 'es': es}).encode(),
      );
      expect(env.stateFor('it')['gems'], 80);
      expect(env.stateFor('es')['gems'], 80, reason: 'gems are shared');
      expect(env.stateFor('it')['completedLessons'], ['it1']);
      expect(env.stateFor('es')['completedLessons'], ['es1', 'es2']);
    });

    test('rejects bad input with the right error', () {
      expect(errorOf('not json'), BackupError.unreadable);
      expect(errorOf('[1,2]'), BackupError.unreadable);
      expect(errorOf('{"hello":1}'), BackupError.notMultilingo);
      expect(errorOf('{"app":"other","schema":2}'), BackupError.notMultilingo);
      expect(errorOf('{"app":"multilingo","schema":99,"courses":{}}'), BackupError.tooNew);
      expect(errorOf('{"app":"multilingo","schema":2,"courses":{}}'), BackupError.damaged);
      expect(errorOf('{"app":"multilingo","schema":"x"}'), BackupError.damaged);
    });

    test('detects edits and truncation', () {
      final text = envelope().encode();
      expect(errorOf(text.replaceFirst('"xp": 42', '"xp": 999999')), BackupError.damaged);
      expect(errorOf(text.substring(0, text.length - 20)), BackupError.unreadable);
    });

    test('labels are trimmed and capped', () {
      expect(cleanLabel('  hi  '), 'hi');
      expect(cleanLabel('a' * 100).length, maxLabelLength);
    });

    test('unknown future courses survive a decode', () {
      final env = envelope(states: {
        'it': AppState().toJson(),
        'es': {'completedLessons': ['x']},
      });
      final back = BackupEnvelope.decode(env.encode());
      expect(back.courses.keys, containsAll(['it', 'es']));
      expect(back.courses['es']!['completedLessons'], ['x']);
    });
  });

  group('sanitize', () {
    test('clamps hand-edited values', () {
      final s = (AppState()
            ..hearts = 99
            ..gems = -5
            ..freezes = 9
            ..dailyGoalXp = 7
            ..themeMode = 'neon'
            ..leagueTier = 50
            ..wordBox = {'a': 99}
            ..name = '   ')
          .sanitized();
      expect(s.hearts, maxHearts);
      expect(s.gems, 0);
      expect(s.freezes, 2);
      expect(s.dailyGoalXp, 20);
      expect(s.themeMode, 'system');
      expect(s.leagueTier, 9);
      expect(s.wordBox['a'], 5);
      expect(s.name, 'You');
    });
  });

  group('service', () {
    test('rolling file is one file, overwritten in place', () async {
      final (c, dir) = await boot();
      final service = c.read(backupServiceProvider);
      await service.writeRolling();
      c.read(appProvider.notifier).setDailyGoal(30);
      final file = await service.writeRolling();
      final names = dir.listSync().map((e) => e.uri.pathSegments.last).toList();
      expect(names, ['duolingo-backup.json']);
      final env = BackupEnvelope.decode(await file.readAsString());
      expect(env.stateFor('it')['dailyGoalXp'], 30);
    });

    test('checkpoints are capped per kind and newest first', () async {
      final (c, _) = await boot();
      final service = c.read(backupServiceProvider);
      for (var i = 0; i < 8; i++) {
        await service.createCheckpoint('m$i');
      }
      for (var i = 0; i < 4; i++) {
        await service.createCheckpoint('a$i', kind: BackupKind.auto);
      }
      final list = service.checkpoints();
      expect(list.where((e) => e.kind == BackupKind.manual).length, maxManualCheckpoints);
      expect(list.where((e) => e.kind == BackupKind.auto).length, maxAutoCheckpoints);
      expect(list.first.label, 'a3');
      expect(list.map((e) => e.label), contains('m7'));
      expect(list.map((e) => e.label), isNot(contains('m0')));
    });

    test('rename and delete', () async {
      final (c, _) = await boot();
      final service = c.read(backupServiceProvider);
      final cp = await service.createCheckpoint('one');
      await service.renameCheckpoint(cp.id, 'two');
      expect(service.checkpoints().single.label, 'two');
      await service.renameCheckpoint(cp.id, '   ');
      expect(service.checkpoints().single.label, 'two');
      await service.deleteCheckpoint(cp.id);
      expect(service.checkpoints(), isEmpty);
    });

    test('blank label falls back to the date', () async {
      final (c, _) = await boot();
      final cp = await c.read(backupServiceProvider).createCheckpoint('  ');
      expect(cp.label, '2026-03-02');
    });

    test('restore replaces progress, sanitizes, and can be undone', () async {
      final (c, _) = await boot();
      final service = c.read(backupServiceProvider);
      final notifier = c.read(appProvider.notifier);
      notifier.setName('Before');
      final good = service.snapshot(label: 'good');

      notifier.setName('After');
      final edited = envelope(states: {
        'it': (AppState()
              ..name = 'Edited'
              ..xp = 500
              ..hearts = 99)
            .toJson(),
      });
      await service.restore(edited);
      var s = c.read(appProvider);
      expect(s.name, 'Edited');
      expect(s.xp, 500);
      expect(s.hearts, maxHearts);
      expect(s.onboarded, isTrue);

      // The state before the restore was saved automatically.
      final undo = service.checkpoints().firstWhere((e) => e.label == 'Before restore');
      expect(undo.kind, BackupKind.auto);
      await service.restore(undo);
      expect(c.read(appProvider).name, 'After');
      await service.restore(good);
      s = c.read(appProvider);
      expect(s.name, 'Before');
    });

    test('restore keeps courses this version cannot show', () async {
      final (c, _) = await boot();
      final service = c.read(backupServiceProvider);
      await service.restore(envelope(states: {
        'it': AppState().toJson(),
        'es': {'completedLessons': ['es1']},
      }));
      final snap = service.snapshot(label: 'now');
      expect(snap.courses.keys, containsAll(['it', 'es']));
      expect(snap.courses['es']!['completedLessons'], ['es1']);
    });

    test('restoring a file with one language drops languages not in it', () async {
      final (c, _) = await boot();
      final service = c.read(backupServiceProvider);
      await service.restore(envelope(states: {
        'it': AppState().toJson(),
        'es': {'completedLessons': ['es1']},
      }));
      await service.restore(envelope());
      expect(service.snapshot(label: 'now').courses.keys, ['it']);
      // The automatic checkpoint from before still has the Spanish data.
      final undo = service.checkpoints().firstWhere((e) => e.label == 'Before restore');
      expect(undo.courses.keys, containsAll(['it', 'es']));
    });

    test('restore without our course is refused and changes nothing', () async {
      final (c, _) = await boot();
      c.read(appProvider.notifier).setName('Keep');
      expect(
        () => c.read(backupServiceProvider).restore(envelope(states: {'es': {'xp': 1}})),
        throwsA(isA<BackupException>()),
      );
      expect(c.read(appProvider).name, 'Keep');
    });

    test('a damaged checkpoint does not hide the others', () async {
      final (c, _) = await boot();
      final prefs = c.read(prefsProvider);
      final service = c.read(backupServiceProvider);
      await service.createCheckpoint('ok');
      final saved = prefs.getStringList('multilingo.checkpoints.v1')!;
      await prefs.setStringList('multilingo.checkpoints.v1', ['garbage', ...saved]);
      expect(service.checkpoints().map((e) => e.label), ['ok']);
    });

    test('restore on a fresh install (not onboarded) works', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      expect(c.read(appProvider).onboarded, isFalse);
      await c.read(backupServiceProvider).restore(envelope());
      expect(c.read(appProvider).onboarded, isTrue);
      expect(c.read(appProvider).xp, 42);
      // No "before restore" point for an empty app.
      expect(c.read(backupServiceProvider).checkpoints(), isEmpty);
    });
  });
}
