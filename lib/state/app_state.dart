import '../domain/dates.dart';
import '../domain/levels.dart';

final validLevels = {for (final l in cefrLevels) l.id};

const maxHearts = 5;
const heartRegen = Duration(hours: 4);
const heartRefillGems = 100;
const streakFreezeGems = 200;
const xpBoostGems = 50;
const xpBoostDuration = Duration(minutes: 15);

/// Everything the learner owns. Mutable on purpose: [AppController] clones it
/// through JSON before each change, so Riverpod always sees a new instance.
class AppState {
  AppState();

  // profile
  bool onboarded = false;
  String name = 'You';
  int dailyGoalXp = 20;
  String level = 'beginner';

  // settings
  bool soundOn = true;
  bool hapticsOn = true;
  bool speechOn = true;
  String themeMode = 'system'; // system | light | dark

  // daily reminder: minutes after midnight, local time (19:00 by default)
  bool reminderOn = false;
  int reminderMinutes = 19 * 60;

  // progress
  int xp = 0;
  Map<String, int> xpByDay = {};
  Set<String> completedLessons = {};
  Map<String, int> lessonRuns = {};
  int perfectLessons = 0;
  Set<String> storiesDone = {};

  // CEFR checkpoints: levels passed, and the best score (percent) per level
  Set<String> passedLevels = {};
  Map<String, int> checkpointBest = {};

  // streak
  int streak = 0;
  int longestStreak = 0;
  String? lastActiveDay;
  int freezes = 0;

  // economy
  int gems = 50;
  int hearts = maxHearts;
  int heartsStamp = 0; // epoch ms when hearts last changed while below max
  int xpBoostUntil = 0; // epoch ms

  // spaced repetition: Leitner box 0..5 and the day a word is next due
  Map<String, int> wordBox = {};
  Map<String, String> wordDue = {};
  Set<String> mistakes = {};
  int wordsCorrect = 0;

  // quests: progress for [questDay]
  String questDay = '';
  Map<String, int> questProgress = {};
  Set<String> questClaimed = {};

  // achievements
  Set<String> achievements = {};
  Set<String> achievementsClaimed = {};

  // league
  int leagueTier = 0;
  String leagueWeek = '';
  String? lastLeagueResult; // e.g. "promoted:3"

  AppState clone() => AppState.fromJson(toJson());

  static String _cleanName(String raw) {
    final n = raw.trim();
    if (n.isEmpty) return 'You';
    return n.length > 20 ? n.substring(0, 20) : n;
  }

  /// Pulls every value back into its legal range. Used on restore, because
  /// a cloud save can come from another phone or an older app version.
  AppState sanitized() {
    const goals = [10, 20, 30, 50];
    const themes = ['system', 'light', 'dark'];
    return clone()
      ..name = _cleanName(name)
      ..dailyGoalXp = goals.contains(dailyGoalXp) ? dailyGoalXp : 20
      ..themeMode = themes.contains(themeMode) ? themeMode : 'system'
      ..reminderMinutes = reminderMinutes.clamp(0, 24 * 60 - 1)
      ..xp = xp < 0 ? 0 : xp
      ..gems = gems < 0 ? 0 : gems
      ..hearts = hearts.clamp(0, maxHearts)
      ..freezes = freezes.clamp(0, 2)
      ..streak = streak < 0 ? 0 : streak
      ..longestStreak = longestStreak < streak ? streak : longestStreak
      ..perfectLessons = perfectLessons < 0 ? 0 : perfectLessons
      ..leagueTier = leagueTier.clamp(0, 9)
      ..wordBox = {
        for (final e in wordBox.entries) e.key: e.value.clamp(0, 5),
      }
      ..passedLevels = passedLevels.where(validLevels.contains).toSet()
      ..checkpointBest = {
        for (final e in checkpointBest.entries)
          if (validLevels.contains(e.key)) e.key: e.value.clamp(0, 100),
      };
  }

  Map<String, dynamic> toJson() => {
        'onboarded': onboarded,
        'name': name,
        'dailyGoalXp': dailyGoalXp,
        'level': level,
        'soundOn': soundOn,
        'hapticsOn': hapticsOn,
        'speechOn': speechOn,
        'themeMode': themeMode,
        'reminderOn': reminderOn,
        'reminderMinutes': reminderMinutes,
        'xp': xp,
        'xpByDay': xpByDay,
        'completedLessons': completedLessons.toList(),
        'lessonRuns': lessonRuns,
        'perfectLessons': perfectLessons,
        'storiesDone': storiesDone.toList(),
        'passedLevels': passedLevels.toList(),
        'checkpointBest': checkpointBest,
        'streak': streak,
        'longestStreak': longestStreak,
        'lastActiveDay': lastActiveDay,
        'freezes': freezes,
        'gems': gems,
        'hearts': hearts,
        'heartsStamp': heartsStamp,
        'xpBoostUntil': xpBoostUntil,
        'wordBox': wordBox,
        'wordDue': wordDue,
        'mistakes': mistakes.toList(),
        'wordsCorrect': wordsCorrect,
        'questDay': questDay,
        'questProgress': questProgress,
        'questClaimed': questClaimed.toList(),
        'achievements': achievements.toList(),
        'achievementsClaimed': achievementsClaimed.toList(),
        'leagueTier': leagueTier,
        'leagueWeek': leagueWeek,
        'lastLeagueResult': lastLeagueResult,
      };

  factory AppState.fromJson(Map<String, dynamic> j) {
    final s = AppState();
    Set<String> set(String k) =>
        ((j[k] as List?) ?? const []).map((e) => e as String).toSet();
    Map<String, int> ints(String k) => ((j[k] as Map?) ?? const {})
        .map((a, b) => MapEntry(a as String, (b as num).toInt()));
    s
      ..onboarded = j['onboarded'] as bool? ?? false
      ..name = j['name'] as String? ?? 'You'
      ..dailyGoalXp = j['dailyGoalXp'] as int? ?? 20
      ..level = j['level'] as String? ?? 'beginner'
      ..soundOn = j['soundOn'] as bool? ?? true
      ..hapticsOn = j['hapticsOn'] as bool? ?? true
      ..speechOn = j['speechOn'] as bool? ?? true
      ..themeMode = j['themeMode'] as String? ?? 'system'
      ..reminderOn = j['reminderOn'] as bool? ?? false
      ..reminderMinutes = j['reminderMinutes'] as int? ?? 19 * 60
      ..xp = j['xp'] as int? ?? 0
      ..xpByDay = ints('xpByDay')
      ..completedLessons = set('completedLessons')
      ..lessonRuns = ints('lessonRuns')
      ..perfectLessons = j['perfectLessons'] as int? ?? 0
      ..storiesDone = set('storiesDone')
      ..passedLevels = set('passedLevels')
      ..checkpointBest = ints('checkpointBest')
      ..streak = j['streak'] as int? ?? 0
      ..longestStreak = j['longestStreak'] as int? ?? 0
      ..lastActiveDay = j['lastActiveDay'] as String?
      ..freezes = j['freezes'] as int? ?? 0
      ..gems = j['gems'] as int? ?? 50
      ..hearts = j['hearts'] as int? ?? maxHearts
      ..heartsStamp = j['heartsStamp'] as int? ?? 0
      ..xpBoostUntil = j['xpBoostUntil'] as int? ?? 0
      ..wordBox = ints('wordBox')
      ..wordDue = ((j['wordDue'] as Map?) ?? const {})
          .map((a, b) => MapEntry(a as String, b as String))
      ..mistakes = set('mistakes')
      ..wordsCorrect = j['wordsCorrect'] as int? ?? 0
      ..questDay = j['questDay'] as String? ?? ''
      ..questProgress = ints('questProgress')
      ..questClaimed = set('questClaimed')
      ..achievements = set('achievements')
      ..achievementsClaimed = set('achievementsClaimed')
      ..leagueTier = j['leagueTier'] as int? ?? 0
      ..leagueWeek = j['leagueWeek'] as String? ?? ''
      ..lastLeagueResult = j['lastLeagueResult'] as String?;
    return s;
  }

  // ---- derived values -------------------------------------------------------

  int xpOn(String day) => xpByDay[day] ?? 0;

  int weekXp(DateTime now) {
    final start = parseDayKey(weekKey(now));
    var sum = 0;
    for (var i = 0; i < 7; i++) {
      sum += xpOn(dayKey(start.add(Duration(days: i))));
    }
    return sum;
  }

  /// Streak as the learner should see it right now. A streak is alive if the
  /// learner was active today or yesterday, or enough freezes cover the gap.
  int streakAt(DateTime now) {
    final last = lastActiveDay;
    if (last == null) return 0;
    final gap = daysBetween(last, dayKey(now));
    if (gap <= 1) return streak;
    return (gap - 1) <= freezes ? streak : 0;
  }

  bool activeToday(DateTime now) => lastActiveDay == dayKey(now);

  bool boostActive(DateTime now) => xpBoostUntil > now.millisecondsSinceEpoch;

  /// Hearts including time-based regeneration.
  int heartsAt(DateTime now) {
    if (hearts >= maxHearts) return maxHearts;
    final elapsed = now.millisecondsSinceEpoch - heartsStamp;
    final gained = elapsed ~/ heartRegen.inMilliseconds;
    return (hearts + gained).clamp(0, maxHearts);
  }

  Duration? nextHeartIn(DateTime now) {
    if (heartsAt(now) >= maxHearts) return null;
    final elapsed = now.millisecondsSinceEpoch - heartsStamp;
    final rem = heartRegen.inMilliseconds - elapsed % heartRegen.inMilliseconds;
    return Duration(milliseconds: rem);
  }

  /// Words the learner has seen, weakest and most overdue first.
  List<String> dueWordIds(DateTime now) {
    final today = dayKey(now);
    final due = wordDue.entries
        .where((e) => e.value.compareTo(today) <= 0)
        .map((e) => e.key)
        .toList();
    due.sort((a, b) => (wordBox[a] ?? 0).compareTo(wordBox[b] ?? 0));
    return due;
  }

  int get wordsLearned => wordBox.values.where((b) => b >= 1).length;
}
