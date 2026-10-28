import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/milestone.dart';
import 'package:multilingo/state/app_state.dart';

AppState withLessons(int n, {Set<String> badges = const {}, int streak = 1}) => AppState()
  ..onboarded = true
  ..completedLessons = {for (var i = 1; i <= n; i++) 'l$i'}
  ..achievements = badges
  ..streak = streak;

void main() {
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
}
