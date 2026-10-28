import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/backup.dart';
import 'package:multilingo/state/app_state.dart';

/// A state where every field differs from its default. If a new field is
/// added to AppState but forgotten in toJson/fromJson, this test fails.
AppState everything() => AppState()
  ..onboarded = true
  ..name = 'Sajon'
  ..dailyGoalXp = 30
  ..level = 'travel'
  ..soundOn = false
  ..hapticsOn = false
  ..speechOn = false
  ..themeMode = 'dark'
  ..reminderOn = true
  ..reminderMinutes = 8 * 60 + 30
  ..xp = 1234
  ..xpByDay = {'2026-03-01': 40, '2026-03-02': 25}
  ..completedLessons = {'u1l1', 'u1l2'}
  ..lessonRuns = {'u1l1': 3}
  ..perfectLessons = 4
  ..storiesDone = {'s1', 's2'}
  ..passedLevels = {'A1'}
  ..checkpointBest = {'A1': 90}
  ..streak = 12
  ..longestStreak = 20
  ..lastActiveDay = '2026-03-02'
  ..freezes = 1
  ..gems = 777
  ..hearts = 3
  ..heartsStamp = 1700000000000
  ..xpBoostUntil = 1700000900000
  ..wordBox = {'u1l1w1': 4}
  ..wordDue = {'u1l1w1': '2026-03-05'}
  ..mistakes = {'u1l1w2'}
  ..wordsCorrect = 99
  ..questDay = '2026-03-02'
  ..questProgress = {'xp20': 12}
  ..questClaimed = {'xp20'}
  ..achievements = {'first', 'streak7'}
  ..achievementsClaimed = {'first'}
  ..leagueTier = 3
  ..leagueWeek = '2026-03-02'
  ..lastLeagueResult = 'promoted:4';

void main() {
  test('every saved field survives export and import', () {
    final original = everything();
    final env = BackupEnvelope.fromStates(
      id: 'x',
      createdAt: DateTime.utc(2026, 3, 2),
      label: 'all',
      kind: BackupKind.manual,
      appVersion: '0.1.0',
      states: {'it': original.toJson()},
    );
    final back = BackupEnvelope.decode(env.encode());
    final restored = AppState.fromJson(back.stateFor('it'));
    expect(jsonEncode(restored.toJson()), jsonEncode(original.toJson()));
  });

  test('every field is filed under the profile or one language, never both', () {
    // A new AppState field that is not listed in backup.dart fails here, so it
    // can never be left out of the backup by accident.
    final keys = AppState().toJson().keys.toSet();
    expect(profileStateKeys.intersection(courseStateKeys), isEmpty);
    expect(
      keys.difference({...profileStateKeys, ...courseStateKeys}),
      isEmpty,
      reason: 'list these AppState fields in profileStateKeys or courseStateKeys',
    );
    expect(
      {...profileStateKeys, ...courseStateKeys}.difference(keys),
      isEmpty,
      reason: 'these listed keys no longer exist in AppState',
    );
  });

  test('the test state really covers every field', () {
    // Each field is non-default, so none is silently skipped by the check
    // above. Compare against a fresh state key by key.
    final fresh = AppState().toJson();
    final full = everything().toJson();
    expect(full.keys.toSet(), fresh.keys.toSet());
    final unchanged = [
      for (final k in fresh.keys)
        if (jsonEncode(fresh[k]) == jsonEncode(full[k])) k,
    ];
    expect(unchanged, isEmpty, reason: 'fields left at default: $unchanged');
  });

  test('sanitizing a valid backup changes nothing', () {
    final s = everything();
    expect(jsonEncode(s.sanitized().toJson()), jsonEncode(s.toJson()));
  });
}
