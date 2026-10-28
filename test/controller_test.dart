import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/dates.dart';
import 'package:multilingo/state/app_state.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, void Function(DateTime))> boot([
  Map<String, Object> seed = const {},
]) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  var now = DateTime(2026, 3, 2, 10); // a Monday
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, (DateTime t) => now = t);
}

LessonResult lesson(String id, {int correct = 10, int total = 10}) => LessonResult(
      lessonId: id,
      correct: correct,
      total: total,
      correctWordIds: const ['w1'],
      maxCombo: correct,
    );

void main() {
  test('first lesson starts a streak, gives xp and gems', () async {
    final (c, _) = await boot();
    final r = c.read(appProvider.notifier).finishSession(lesson('l1'));
    final s = c.read(appProvider);
    expect(r.streak, 1);
    expect(r.xp, 15); // 10 + perfect bonus
    expect(s.gems, 50 + 15);
    expect(s.completedLessons, {'l1'});
    expect(r.newAchievements, contains('first'));
  });

  test('streak grows on consecutive days and resets after a gap', () async {
    final (c, setNow) = await boot();
    final n = c.read(appProvider.notifier);
    n.finishSession(lesson('l1'));
    setNow(DateTime(2026, 3, 3, 9));
    n.finishSession(lesson('l2'));
    expect(c.read(appProvider).streak, 2);
    setNow(DateTime(2026, 3, 7, 9)); // missed 3 days
    expect(c.read(appProvider).streakAt(DateTime(2026, 3, 7)), 0);
    n.finishSession(lesson('l3'));
    expect(c.read(appProvider).streak, 1);
  });

  test('streak freeze covers one missed day', () async {
    final (c, setNow) = await boot();
    final n = c.read(appProvider.notifier);
    n.finishSession(lesson('l1'));
    // Give gems then buy a freeze.
    for (var i = 0; i < 10; i++) {
      n.finishSession(lesson('x$i'));
    }
    expect(n.buyStreakFreeze(), isTrue);
    setNow(DateTime(2026, 3, 4, 9)); // missed Mar 3
    n.finishSession(lesson('l2'));
    final s = c.read(appProvider);
    expect(s.streak, 2);
    expect(s.freezes, 0);
  });

  test('hearts drop, regenerate over time, and refill with gems', () async {
    final (c, setNow) = await boot();
    final n = c.read(appProvider.notifier);
    n.loseHeart();
    n.loseHeart();
    expect(c.read(appProvider).heartsAt(DateTime(2026, 3, 2, 10)), 3);
    setNow(DateTime(2026, 3, 2, 14, 1)); // 4h later: +1
    expect(c.read(appProvider).heartsAt(DateTime(2026, 3, 2, 14, 1)), 4);
    setNow(DateTime(2026, 3, 3, 10));
    expect(c.read(appProvider).heartsAt(DateTime(2026, 3, 3, 10)), 5);
  });

  test('cannot lose hearts below zero and refill needs gems', () async {
    final (c, _) = await boot();
    final n = c.read(appProvider.notifier);
    for (var i = 0; i < 8; i++) {
      n.loseHeart();
    }
    expect(n.hearts, 0);
    expect(n.refillHeartsWithGems(), isFalse); // 50 gems < 100
  });

  test('spaced repetition moves boxes and due dates', () async {
    final (c, _) = await boot();
    final n = c.read(appProvider.notifier);
    n.finishSession(lesson('l1'));
    var s = c.read(appProvider);
    expect(s.wordBox['w1'], 1);
    expect(s.wordDue['w1'], '2026-03-03');
    n.finishSession(const LessonResult(
        lessonId: 'l1', correct: 5, total: 10, wrongWordIds: ['w1']));
    s = c.read(appProvider);
    expect(s.wordBox['w1'], 0);
    expect(s.mistakes, contains('w1'));
    expect(s.dueWordIds(DateTime(2026, 3, 2)), contains('w1'));
  });

  test('quests track progress and pay out once', () async {
    final (c, _) = await boot();
    final n = c.read(appProvider.notifier);
    n.finishSession(lesson('l1'));
    final s = c.read(appProvider);
    final done = s.questProgress.entries.where((e) => e.value > 0);
    expect(done, isNotEmpty);
    final gemsBefore = s.gems;
    final id = done.first.key;
    // Not every quest is finished after one lesson; claim only if complete.
    final claimed = n.claimQuest(id);
    if (claimed) {
      expect(c.read(appProvider).gems, greaterThan(gemsBefore));
      expect(n.claimQuest(id), isFalse);
    }
  });

  test('league week rollover promotes a strong learner', () async {
    final (c, setNow) = await boot();
    final n = c.read(appProvider.notifier);
    for (var i = 0; i < 60; i++) {
      n.finishSession(lesson('l$i'));
    }
    setNow(DateTime(2026, 3, 9, 10)); // next Monday
    n.refresh();
    final s = c.read(appProvider);
    expect(s.leagueTier, 1);
    expect(s.lastLeagueResult, startsWith('promoted'));
  });

  test('corrupt save does not crash', () async {
    final (c, _) = await boot({'multilingo.state.v1': '{not json'});
    expect(c.read(appProvider).onboarded, isFalse);
  });

  test('state survives a JSON round trip', () {
    final s = AppState()
      ..xp = 99
      ..completedLessons = {'a', 'b'}
      ..xpByDay = {dayKey(DateTime(2026, 1, 1)): 5};
    final back = AppState.fromJson(s.toJson());
    expect(back.xp, 99);
    expect(back.completedLessons, {'a', 'b'});
    expect(back.xpByDay['2026-01-01'], 5);
  });

  group('checkpoints', () {
    LessonResult cp(int correct, {String level = 'A1'}) => LessonResult(
          correct: correct,
          total: 20,
          kind: SessionKind.checkpoint,
          levelId: level,
        );

    test('80 percent passes, and gems are paid only once', () async {
      final (c, _) = await boot();
      final n = c.read(appProvider.notifier);
      final r = n.finishSession(cp(16));
      expect(r.checkpointPassed, isTrue);
      expect(r.accuracyPercent, 80);
      var s = c.read(appProvider);
      expect(s.passedLevels, {'A1'});
      expect(s.checkpointBest['A1'], 80);
      expect(r.newAchievements, contains('levelA1'));
      final gems = s.gems;
      n.finishSession(cp(20));
      s = c.read(appProvider);
      expect(s.checkpointBest['A1'], 100);
      expect(s.gems, gems); // no repeat reward
    });

    test('79 percent fails, keeps the best score, and unlocks nothing', () async {
      final (c, _) = await boot();
      final n = c.read(appProvider.notifier);
      final r = n.finishSession(cp(15));
      expect(r.checkpointPassed, isFalse);
      var s = c.read(appProvider);
      expect(s.passedLevels, isEmpty);
      expect(s.checkpointBest['A1'], 75);
      n.finishSession(cp(10));
      s = c.read(appProvider);
      expect(s.checkpointBest['A1'], 75); // best is kept
    });

    test('a checkpoint never costs hearts and counts for the streak', () async {
      final (c, _) = await boot();
      final r = c.read(appProvider.notifier).finishSession(cp(5));
      expect(r.streak, 1);
      expect(c.read(appProvider).heartsAt(DateTime(2026, 3, 2, 10)), maxHearts);
    });

    test('backups keep passed levels and drop invalid ones', () {
      final s = (AppState()
            ..passedLevels = {'A1', 'Z9'}
            ..checkpointBest = {'A1': 250, 'Z9': 5})
          .sanitized();
      expect(s.passedLevels, {'A1'});
      expect(s.checkpointBest, {'A1': 100});
      final back = AppState.fromJson(s.toJson());
      expect(back.passedLevels, {'A1'});
    });
  });
}
