import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/reminder_plan.dart';

List<PlannedReminder> plan({
  required DateTime now,
  int minutes = 19 * 60,
  bool practised = false,
  int streak = 0,
}) =>
    planReminders(
      now: now,
      minutes: minutes,
      practisedToday: practised,
      streak: streak,
      languageName: 'German',
    );

void main() {
  test('plans today when the time has not passed yet', () {
    final p = plan(now: DateTime(2026, 3, 2, 10));
    expect(p.length, reminderDaysAhead);
    expect(p.first.when, DateTime(2026, 3, 2, 19));
    expect(p.last.when, DateTime(2026, 3, 15, 19));
  });

  test('skips today when the time has passed', () {
    final p = plan(now: DateTime(2026, 3, 2, 20));
    expect(p.length, reminderDaysAhead - 1);
    expect(p.first.when, DateTime(2026, 3, 3, 19));
  });

  test('skips today when the learner already practised', () {
    final p = plan(now: DateTime(2026, 3, 2, 10), practised: true);
    expect(p.first.when, DateTime(2026, 3, 3, 19));
  });

  test('ids are unique and stable per day offset', () {
    final p = plan(now: DateTime(2026, 3, 2, 10));
    expect(p.map((r) => r.id).toSet().length, p.length);
    expect(p.first.id, reminderIdBase);
  });

  test('time of day follows the setting, also across a month end', () {
    final p = plan(now: DateTime(2026, 1, 30, 6), minutes: 7 * 60 + 30);
    expect(p.first.when, DateTime(2026, 1, 30, 7, 30));
    expect(p[2].when, DateTime(2026, 2, 1, 7, 30));
  });

  test('text follows the streak and names the language', () {
    expect(plan(now: DateTime(2026, 3, 2, 10)).first.title, 'Time for German');
    expect(plan(now: DateTime(2026, 3, 2, 10), streak: 3).first.title, 'Keep your 3 day streak');
    expect(plan(now: DateTime(2026, 3, 2, 10), streak: 12).first.title,
        'Do not lose your 12 day streak');
    expect(plan(now: DateTime(2026, 3, 2, 10)).any((r) => r.body.contains('German words')), isTrue);
  });
}
