import 'package:multilingo/state/app_state.dart';

/// A state where every field differs from its default. If a new field is
/// added to AppState but forgotten in toJson/fromJson, the tests that use this
/// fail.
AppState everything() => AppState()
  ..onboarded = true
  ..name = 'Tester'
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
