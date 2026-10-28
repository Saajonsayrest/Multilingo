import '../state/app_state.dart';

/// Streak lengths that count as a milestone.
const streakMilestones = {7, 14, 30, 50, 100, 365};

/// Every this many finished lessons is a milestone.
const lessonMilestoneEvery = 5;

/// A short text if the change from [before] to [after] is worth a restore
/// point, like Duolingo's "you reached something" moments. Null otherwise.
///
/// Only steady progress counts. A restore, a reset or a language switch
/// replaces the state in one jump, so those never look like a milestone.
String? milestoneFor(AppState before, AppState after) {
  bool grew(Set<String> a, Set<String> b) => b.length > a.length && a.difference(b).isEmpty;

  final newLevels = after.passedLevels.difference(before.passedLevels);
  if (grew(before.passedLevels, after.passedLevels) && newLevels.length == 1) {
    return '${newLevels.single} level passed';
  }
  if (grew(before.achievements, after.achievements)) return 'New badge';
  if (after.streak > before.streak &&
      after.streak - before.streak == 1 &&
      streakMilestones.contains(after.streak)) {
    return '${after.streak} day streak';
  }
  final lessons = after.completedLessons.length;
  if (grew(before.completedLessons, after.completedLessons) &&
      lessons - before.completedLessons.length == 1 &&
      lessons % lessonMilestoneEvery == 0) {
    return '$lessons lessons done';
  }
  return null;
}
