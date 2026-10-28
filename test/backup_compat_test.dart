import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/backup.dart';
import 'package:multilingo/state/app_state.dart';
import 'package:multilingo/state/backup_service.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backward compatibility guard.
///
/// The files in test/fixtures/backups/ are real backup files from each file
/// format, frozen. They must keep restoring forever, whatever features are
/// added later. Never edit or regenerate one. When the format changes, add a
/// new fixture (see tool/fixture_checksum.dart) and list it below.
const fixtureFiles = {
  1: 'schema1_bare_state.json',
  2: 'schema2_whole_state.json',
  3: 'schema3_profile_and_courses.json',
};

String fixture(String name) => File('test/fixtures/backups/$name').readAsStringSync();

Future<ProviderContainer> boot() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final dir = await Directory.systemTemp.createTemp('multilingo_compat_test');
  addTearDown(() => dir.delete(recursive: true));
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    backupDirProvider.overrideWithValue(Future.value(dir)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('there is a frozen fixture for every file format ever shipped', () {
    expect(fixtureFiles.keys, [for (var i = 1; i <= backupSchema; i++) i],
        reason: 'format $backupSchema needs a frozen fixture in $fixtureFiles');
    for (final name in fixtureFiles.values) {
      expect(File('test/fixtures/backups/$name').existsSync(), isTrue, reason: name);
    }
  });

  for (final entry in fixtureFiles.entries) {
    test('a schema ${entry.key} file still restores everything', () async {
      final c = await boot();
      final service = c.read(backupServiceProvider);
      await service.restore(BackupEnvelope.decode(fixture(entry.value)));
      final s = c.read(appProvider);
      expect(s.name, 'Giulia');
      expect(s.dailyGoalXp, 30);
      expect(s.level, 'intermediate');
      expect(s.themeMode, 'dark');
      expect(s.soundOn, isFalse);
      expect(s.xp, 1250);
      expect(s.gems, 340);
      // Hearts refill with time, and the file is old, so at least 4 is right.
      expect(s.hearts, inInclusiveRange(4, maxHearts));
      expect(s.streak, 12);
      expect(s.longestStreak, 20);
      expect(s.freezes, 1);
      expect(s.completedLessons, {'u1l1', 'u1l2', 'u2l1'});
      expect(s.passedLevels, {'A1'});
      expect(s.checkpointBest, {'A1': 90});
      expect(s.wordBox, {'u1l1w1': 3});
      expect(s.mistakes, {'u1l1w2'});
      expect(s.storiesDone, {'cafe'});
      expect(s.leagueTier, 2);
      expect(s.achievements, {'first'});
      expect(s.onboarded, isTrue);
    });
  }

  test('a language this version cannot show survives restore and save', () async {
    final c = await boot();
    final service = c.read(backupServiceProvider);
    for (final name in [fixtureFiles[2]!, fixtureFiles[3]!]) {
      await service.restore(BackupEnvelope.decode(fixture(name)));
      final out = BackupEnvelope.decode(service.snapshot(label: 'x').encode());
      expect(out.courses['es'], {'completedLessons': ['es1']}, reason: name);
    }
  });

  test('a file saved by a later app with extra and missing fields still restores', () async {
    // Same format, but with a field this version does not know and one it
    // expects missing. Unknown fields are ignored, missing ones get defaults.
    final json = jsonDecode(fixture(fixtureFiles[3]!)) as Map<String, dynamic>;
    final profile = Map<String, dynamic>.from(json['profile'] as Map)
      ..['languageUi'] = 'es'
      ..remove('hapticsOn');
    final courses = (json['courses'] as Map).cast<String, Map<String, dynamic>>();
    final changed = {
      ...json,
      'profile': profile,
      'checksum': checksumV3('it', profile, courses),
    };
    final c = await boot();
    await c.read(backupServiceProvider).restore(BackupEnvelope.decode(jsonEncode(changed)));
    final s = c.read(appProvider);
    expect(s.xp, 1250);
    expect(s.hapticsOn, AppState().hapticsOn);
  });

  test('a file from a newer format is refused with a clear reason, not read wrongly', () {
    final json = jsonDecode(fixture(fixtureFiles[3]!)) as Map<String, dynamic>;
    final future = jsonEncode({...json, 'schema': backupSchema + 1});
    expect(
      () => BackupEnvelope.decode(future),
      throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.tooNew)),
    );
  });

  test('the user only ever sees one fixed file name', () async {
    final c = await boot();
    final service = c.read(backupServiceProvider);
    final dir = (await service.rollingFile()).parent;
    for (var i = 0; i < 4; i++) {
      await service.writeRolling();
    }
    expect(dir.listSync().map((e) => e.uri.pathSegments.last), [backupFileName]);
    expect(backupFileName, 'duolingo-backup.json');
    expect(RegExp(r'\(\d+\)|-\d+\.json').hasMatch(backupFileName), isFalse);
  });
}
