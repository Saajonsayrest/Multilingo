import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/dates.dart';
import '../domain/reminder_plan.dart';
import 'controller.dart';
import 'course_state.dart';

/// Shows reminders on the phone. An interface so tests can use a fake.
abstract class ReminderScheduler {
  /// Asks the learner for permission to show notifications. True if granted.
  Future<bool> requestPermission();

  /// Removes every reminder, then schedules [plan].
  Future<void> replaceAll(List<PlannedReminder> plan);
}

class LocalReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
        tzdata.initializeTimeZones();
        try {
          final zone = await FlutterTimezone.getLocalTimezone();
          tz.setLocalLocation(tz.getLocation(zone.identifier));
        } catch (_) {
          // Falls back to UTC: reminders then fire at the wrong hour but never crash.
        }
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            // Permission is asked when the learner turns reminders on, not at launch.
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        );
      }();

  @override
  Future<bool> requestPermission() async {
    try {
      await _init();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.requestNotificationsPermission() ??
              false;
        case TargetPlatform.iOS:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                      IOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async {
    try {
      await _init();
      await _plugin.cancelAll();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'A nudge to practise at the time you choose',
        ),
        iOS: DarwinNotificationDetails(),
      );
      for (final r in plan) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: tz.TZDateTime.from(r.when, tz.local),
          notificationDetails: details,
          // Inexact: the reminder may come a few minutes late, and the app
          // does not need the exact-alarm permission.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // A reminder problem must never break the app.
    }
  }
}

final reminderSchedulerProvider =
    Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

/// Keeps the scheduled reminders in line with the settings, the streak and
/// whether the learner practised today.
class ReminderService {
  ReminderService(this._ref);

  final Ref _ref;
  Timer? _debounce;
  String? _lastSignature;

  /// Run soon, and only once if called many times in a row.
  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), sync);
  }

  Future<void> sync() async {
    final s = _ref.read(appProvider);
    final now = _ref.read(clockProvider)();
    final plan = s.reminderOn
        ? planReminders(
            now: now,
            minutes: s.reminderMinutes,
            practisedToday: s.lastActiveDay == dayKey(now),
            streak: s.streakAt(now),
            languageName: _ref.read(courseProvider).language.name,
          )
        : const <PlannedReminder>[];
    final signature = plan.map((r) => '${r.id}|${r.when}|${r.title}|${r.body}').join(';');
    if (signature == _lastSignature) return;
    _lastSignature = signature;
    await _ref.read(reminderSchedulerProvider).replaceAll(plan);
  }

  /// Turns reminders on. Asks for permission first; returns false (and does
  /// nothing) when the learner says no.
  Future<bool> enable() async {
    final granted = await _ref.read(reminderSchedulerProvider).requestPermission();
    if (!granted) return false;
    _ref.read(appProvider.notifier).setReminder(on: true);
    await sync();
    return true;
  }

  Future<void> disable() async {
    _ref.read(appProvider.notifier).setReminder(on: false);
    await sync();
  }

  void dispose() => _debounce?.cancel();
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final s = ReminderService(ref);
  ref.onDispose(s.dispose);
  return s;
});
