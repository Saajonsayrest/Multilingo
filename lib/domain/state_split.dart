/// How the app state is split for saving and for switching language.
///
/// `profile` holds what belongs to the learner (name, settings, gems, hearts,
/// streak, XP, quests, league). A course holds only what belongs to one
/// language (lessons, words, levels), so an app that teaches more languages
/// keeps each language apart and shares the rest.
///
/// Every field of AppState must be listed in exactly one of
/// [profileStateKeys] or [courseStateKeys]. A test fails when a new field is
/// added to AppState without being listed, so nothing is ever left out of a
/// save.
library;

/// Shared by every language.
const profileStateKeys = {
  'onboarded',
  'name',
  'dailyGoalXp',
  'soundOn',
  'hapticsOn',
  'speechOn',
  'themeMode',
  'reminderOn',
  'reminderMinutes',
  'xp',
  'xpByDay',
  'streak',
  'longestStreak',
  'lastActiveDay',
  'freezes',
  'gems',
  'hearts',
  'heartsStamp',
  'xpBoostUntil',
  'questDay',
  'questProgress',
  'questClaimed',
  'achievements',
  'achievementsClaimed',
  'leagueTier',
  'leagueWeek',
  'lastLeagueResult',
};

/// Belongs to one language only.
const courseStateKeys = {
  'level',
  'completedLessons',
  'lessonRuns',
  'perfectLessons',
  'storiesDone',
  'passedLevels',
  'checkpointBest',
  'wordBox',
  'wordDue',
  'mistakes',
  'wordsCorrect',
};

/// Splits one AppState JSON map into (profile, course). A key that is in
/// neither list goes to the profile, so it is still saved.
(Map<String, dynamic>, Map<String, dynamic>) splitState(Map<String, dynamic> state) {
  final profile = <String, dynamic>{};
  final course = <String, dynamic>{};
  for (final e in state.entries) {
    (courseStateKeys.contains(e.key) ? course : profile)[e.key] = e.value;
  }
  return (profile, course);
}

/// The reverse of [splitState]. The profile wins when both have a key.
Map<String, dynamic> mergeState(
  Map<String, dynamic> profile,
  Map<String, dynamic> course,
) =>
    {...course, ...profile};
