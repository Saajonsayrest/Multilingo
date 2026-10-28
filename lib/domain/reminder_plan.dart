/// One reminder to show at [when] (local time).
class PlannedReminder {
  const PlannedReminder(this.id, this.when, this.title, this.body);

  final int id;
  final DateTime when;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedReminder($id, $when, $title)';
}

/// How many days ahead reminders are scheduled. The plan is rebuilt every time
/// the app opens or a lesson ends, so it never runs out while the learner is
/// active, and it stops by itself after two weeks away.
const reminderDaysAhead = 14;

/// First notification id used by reminders.
const reminderIdBase = 1000;

/// Builds the reminders for the coming days, like Duolingo does:
/// - none for today if the learner already practised today,
/// - none for today if the chosen time has passed,
/// - the text changes with the streak, so a long streak sounds urgent.
///
/// [minutes] is the time of day, minutes after midnight.
List<PlannedReminder> planReminders({
  required DateTime now,
  required int minutes,
  required bool practisedToday,
  required int streak,
  required String languageName,
}) {
  final out = <PlannedReminder>[];
  for (var i = 0; i < reminderDaysAhead; i++) {
    final when = DateTime(now.year, now.month, now.day + i, minutes ~/ 60, minutes % 60);
    if (i == 0 && (practisedToday || !when.isAfter(now))) continue;
    out.add(PlannedReminder(
      reminderIdBase + i,
      when,
      _title(streak, languageName),
      _body(languageName, i),
    ));
  }
  return out;
}

String _title(int streak, String language) {
  if (streak >= 7) return 'Do not lose your $streak day streak';
  if (streak >= 2) return 'Keep your $streak day streak';
  return 'Time for $language';
}

String _body(String language, int dayIndex) {
  final nudges = [
    'A short lesson takes about 5 minutes.',
    'Your $language words are waiting for you.',
    'Five minutes today makes tomorrow easier.',
    'Pip misses you. One quick lesson?',
  ];
  return nudges[dayIndex % nudges.length];
}
