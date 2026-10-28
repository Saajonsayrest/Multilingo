import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/backup.dart';
import 'package:multilingo/domain/backup_milestone.dart';
import 'package:multilingo/state/app_state.dart';
import 'package:multilingo/state/backup_service.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppState withLessons(int n, {Set<String> badges = const {}, int streak = 1}) => AppState()
  ..onboarded = true
  ..completedLessons = {for (var i = 1; i <= n; i++) 'l$i'}
  ..achievements = badges
  ..streak = streak;

void main() {
  group('what counts as a milestone', () {
    test('every 5th lesson, not the ones between', () {
      expect(milestoneFor(withLessons(4), withLessons(5)), '5 lessons done');
      expect(milestoneFor(withLessons(9), withLessons(10)), '10 lessons done');
      expect(milestoneFor(withLessons(5), withLessons(6)), isNull);
      expect(milestoneFor(withLessons(0), withLessons(1)), isNull);
    });

    test('a new badge', () {
      expect(milestoneFor(withLessons(1), withLessons(2, badges: {'first'})), 'New badge');
      expect(milestoneFor(withLessons(2, badges: {'first'}), withLessons(3, badges: {'first'})), isNull);
    });

    test('a level passed', () {
      final before = withLessons(3);
      final after = withLessons(3)..passedLevels = {'A1'};
      expect(milestoneFor(before, after), 'A1 level passed');
    });

    test('streak records', () {
      expect(milestoneFor(withLessons(1, streak: 6), withLessons(1, streak: 7)), '7 day streak');
      expect(milestoneFor(withLessons(1, streak: 7), withLessons(1, streak: 8)), isNull);
      expect(milestoneFor(withLessons(1, streak: 29), withLessons(1, streak: 30)), '30 day streak');
    });

    test('a restore, reset or language switch is never a milestone', () {
      // Lessons jump from 3 to 10 at once (restore): not steady progress.
      expect(milestoneFor(withLessons(3), withLessons(10)), isNull);
      // Everything disappears (reset).
      expect(milestoneFor(withLessons(10), withLessons(0)), isNull);
      // Different lessons, same count (language switch).
      final other = AppState()
        ..onboarded = true
        ..completedLessons = {'de_1', 'de_2', 'de_3', 'de_4', 'de_5'};
      expect(milestoneFor(withLessons(4), other), isNull);
    });
  });

  group('the backup service at a milestone', () {
    Future<(ProviderContainer, Directory)> boot() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dir = await Directory.systemTemp.createTemp('multilingo_milestone_test');
      addTearDown(() => dir.delete(recursive: true));
      final c = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(prefs),
        backupDirProvider.overrideWithValue(Future.value(dir)),
        clockProvider.overrideWithValue(() => DateTime(2026, 3, 2, 10)),
      ]);
      addTearDown(c.dispose);
      c.read(appProvider.notifier).completeOnboarding(
          name: 'Sajon', dailyGoalXp: 20, level: 'beginner');
      return (c, dir);
    }

    test('the file is written at once, without the few seconds wait', () async {
      final (c, dir) = await boot();
      final svc = c.read(backupServiceProvider);
      final file = File('${dir.path}/$backupFileName');
      expect(file.existsSync(), isFalse);

      await svc.noteChange(withLessons(4), withLessons(5));
      expect(file.existsSync(), isTrue, reason: 'written straight away');
      expect(c.read(backupHintProvider), '5 lessons done');
    });

    test('an ordinary change writes nothing at once and gives no hint', () async {
      final (c, dir) = await boot();
      await c.read(backupServiceProvider).noteChange(withLessons(5), withLessons(6));
      expect(File('${dir.path}/$backupFileName').existsSync(), isFalse);
      expect(c.read(backupHintProvider), isNull);
    });

    test('the reminder shows once a day, but the file is always saved', () async {
      final (c, dir) = await boot();
      final svc = c.read(backupServiceProvider);
      await svc.noteChange(withLessons(4), withLessons(5));
      expect(c.read(backupHintProvider), '5 lessons done');
      c.read(backupHintProvider.notifier).clear();

      File('${dir.path}/$backupFileName').deleteSync();
      await svc.noteChange(withLessons(9), withLessons(10));
      expect(c.read(backupHintProvider), isNull, reason: 'already reminded today');
      expect(File('${dir.path}/$backupFileName').existsSync(), isTrue);
    });

    test('not before the first-run screens are done', () async {
      final (c, dir) = await boot();
      final fresh = withLessons(5)..onboarded = false;
      await c.read(backupServiceProvider).noteChange(withLessons(4), fresh);
      expect(File('${dir.path}/$backupFileName').existsSync(), isFalse);
    });
  });
}
