import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/reminder_plan.dart';
import 'package:multilingo/state/controller.dart';
import 'package:multilingo/state/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeScheduler implements ReminderScheduler {
  FakeScheduler({this.grant = true});

  final bool grant;
  final List<List<PlannedReminder>> calls = [];

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async => calls.add(plan);
}

Future<(ProviderContainer, FakeScheduler, void Function(DateTime))> boot({
  bool grant = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fake = FakeScheduler(grant: grant);
  var now = DateTime(2026, 3, 2, 10);
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
    reminderSchedulerProvider.overrideWithValue(fake),
  ]);
  addTearDown(c.dispose);
  return (c, fake, (DateTime t) => now = t);
}

void main() {
  test('reminders are off by default and nothing is scheduled', () async {
    final (c, fake, _) = await boot();
    expect(c.read(appProvider).reminderOn, isFalse);
    await c.read(reminderServiceProvider).sync();
    expect(fake.calls.single, isEmpty);
  });

  test('turning on asks permission, then schedules today at 19:00', () async {
    final (c, fake, _) = await boot();
    final ok = await c.read(reminderServiceProvider).enable();
    expect(ok, isTrue);
    expect(c.read(appProvider).reminderOn, isTrue);
    final plan = fake.calls.last;
    expect(plan.first.when, DateTime(2026, 3, 2, 19));
    expect(plan.length, reminderDaysAhead);
  });

  test('a refused permission keeps reminders off', () async {
    final (c, fake, _) = await boot(grant: false);
    final ok = await c.read(reminderServiceProvider).enable();
    expect(ok, isFalse);
    expect(c.read(appProvider).reminderOn, isFalse);
    expect(fake.calls, isEmpty);
  });

  test('turning off removes every reminder', () async {
    final (c, fake, _) = await boot();
    final svc = c.read(reminderServiceProvider);
    await svc.enable();
    await svc.disable();
    expect(c.read(appProvider).reminderOn, isFalse);
    expect(fake.calls.last, isEmpty);
  });

  test('syncing again with nothing changed does not reschedule', () async {
    final (c, fake, _) = await boot();
    final svc = c.read(reminderServiceProvider);
    await svc.enable();
    final before = fake.calls.length;
    await svc.sync();
    await svc.sync();
    expect(fake.calls.length, before);
  });

  test('a new time changes the plan', () async {
    final (c, fake, _) = await boot();
    final svc = c.read(reminderServiceProvider);
    await svc.enable();
    c.read(appProvider.notifier).setReminderTime(8 * 60 + 15);
    await svc.sync();
    expect(fake.calls.last.first.when, DateTime(2026, 3, 3, 8, 15),
        reason: '08:15 today has already passed at 10:00');
  });

  test('practising today moves the first reminder to tomorrow', () async {
    final (c, fake, _) = await boot();
    final svc = c.read(reminderServiceProvider);
    await svc.enable();
    expect(fake.calls.last.first.when, DateTime(2026, 3, 2, 19));
    c.read(appProvider.notifier).finishSession(
          const LessonResult(lessonId: 'x', correct: 10, total: 10),
        );
    await svc.sync();
    expect(fake.calls.last.first.when, DateTime(2026, 3, 3, 19));
    expect(fake.calls.last.first.title, contains('Time for Italian'));
  });

  test('the reminder time is saved and survives bad values', () async {
    final (c, _, _) = await boot();
    final ctrl = c.read(appProvider.notifier);
    ctrl.setReminderTime(99999);
    expect(c.read(appProvider).reminderMinutes, 24 * 60 - 1);
    ctrl.setReminderTime(-5);
    expect(c.read(appProvider).reminderMinutes, 0);
  });
}
