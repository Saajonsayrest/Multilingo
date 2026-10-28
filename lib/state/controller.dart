import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/languages.dart';
import '../domain/backup.dart';
import '../domain/dates.dart';
import '../domain/league.dart';
import '../domain/levels.dart';
import '../domain/quests.dart';
import 'app_state.dart';
import 'course_state.dart';

const _prefsKey = 'multilingo.state.v1';
const _boxIntervals = [0, 1, 2, 4, 8, 16];

/// Must be overridden in main() with the loaded instance.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider not overridden'),
);

/// Injectable clock so tests can control time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final appProvider =
    NotifierProvider<AppController, AppState>(AppController.new);

/// What the learner did in one lesson, story or practice run.
class LessonResult {
  const LessonResult({
    this.lessonId,
    required this.correct,
    required this.total,
    this.correctWordIds = const [],
    this.wrongWordIds = const [],
    this.maxCombo = 0,
    this.kind = SessionKind.lesson,
    this.levelId,
  });

  final String? lessonId;

  /// For checkpoints: the CEFR level being tested.
  final String? levelId;
  final int correct;
  final int total;
  final List<String> correctWordIds;
  final List<String> wrongWordIds;
  final int maxCombo;
  final SessionKind kind;

  bool get perfect => total > 0 && correct == total;
}

enum SessionKind { lesson, practice, story, checkpoint }

class Reward {
  const Reward({
    required this.xp,
    required this.gems,
    required this.streak,
    required this.streakIncreased,
    required this.goalJustMet,
    required this.newAchievements,
    required this.boosted,
    this.checkpointLevel,
    this.checkpointPassed = false,
    this.accuracyPercent = 0,
  });

  /// Set when the session was a level checkpoint.
  final String? checkpointLevel;
  final bool checkpointPassed;
  final int accuracyPercent;

  final int xp;
  final int gems;
  final int streak;
  final bool streakIncreased;
  final bool goalJustMet;
  final List<String> newAchievements;
  final bool boosted;
}

class AppController extends Notifier<AppState> {
  DateTime get _now => ref.read(clockProvider)();

  @override
  AppState build() {
    final raw = ref.read(prefsProvider).getString(_prefsKey);
    var s = AppState();
    if (raw != null) {
      try {
        s = AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt save: start fresh rather than crash on launch.
      }
    }
    _rollover(s);
    return s;
  }

  void _save(AppState s) {
    ref.read(prefsProvider).setString(_prefsKey, jsonEncode(s.toJson()));
  }

  void _update(void Function(AppState s) change) {
    final s = state.clone();
    change(s);
    _save(s);
    state = s;
  }

  // ---- day / week rollover ---------------------------------------------------

  void _rollover(AppState s) {
    final now = _now;
    final today = dayKey(now);
    if (s.questDay != today) {
      s.questDay = today;
      s.questProgress = {};
      s.questClaimed = {};
    }
    _bankHearts(s, now);
    // League week.
    final wk = weekKey(now);
    if (s.leagueWeek.isEmpty) {
      s.leagueWeek = wk;
    } else if (s.leagueWeek != wk) {
      final start = parseDayKey(s.leagueWeek);
      var prevXp = 0;
      for (var i = 0; i < 7; i++) {
        prevXp += s.xpOn(dayKey(start.add(Duration(days: i))));
      }
      final board = buildLeague(
        weekKey: s.leagueWeek,
        tier: s.leagueTier,
        yourXp: prevXp,
        yourName: s.name,
        weekFraction: 1,
      );
      final rank = board.indexWhere((e) => e.isYou) + 1;
      final outcome = outcomeForRank(rank, s.leagueTier);
      switch (outcome) {
        case LeagueOutcome.promoted:
          s.leagueTier++;
          s.gems += 30;
          s.achievements.add('promo');
        case LeagueOutcome.demoted:
          s.leagueTier--;
        case LeagueOutcome.stayed:
          break;
      }
      s.lastLeagueResult = '${outcome.name}:$rank';
      s.leagueWeek = wk;
    }
  }

  /// Call when the app returns to the foreground.
  void refresh() => _update(_rollover);

  // ---- profile & settings ------------------------------------------------------

  void completeOnboarding({
    required String name,
    required int dailyGoalXp,
    required String level,
  }) =>
      _update((s) {
        s.onboarded = true;
        s.name = name.trim().isEmpty ? 'You' : name.trim();
        s.dailyGoalXp = dailyGoalXp;
        s.level = level;
      });

  void setDailyGoal(int xp) => _update((s) => s.dailyGoalXp = xp);
  void setName(String n) =>
      _update((s) => s.name = n.trim().isEmpty ? 'You' : n.trim());
  void setSound(bool v) => _update((s) => s.soundOn = v);
  void setHaptics(bool v) => _update((s) => s.hapticsOn = v);
  void setSpeech(bool v) => _update((s) => s.speechOn = v);
  void setThemeMode(String m) => _update((s) => s.themeMode = m);
  void setReminder({required bool on}) => _update((s) => s.reminderOn = on);

  /// [minutes] is the time of day, minutes after midnight.
  void setReminderTime(int minutes) =>
      _update((s) => s.reminderMinutes = minutes.clamp(0, 24 * 60 - 1));

  /// Replaces everything with a restored copy (already sanitised).
  void restoreFrom(AppState restored) {
    final s = restored.clone();
    _rollover(s);
    _save(s);
    state = s;
  }

  void resetAll() {
    final fresh = AppState();
    // Every language starts over, not just the one on screen.
    writeStash(ref.read(prefsProvider), {});
    _save(fresh);
    state = fresh;
  }

  /// Changes the language being learned. The shared profile (name, gems,
  /// hearts, streak, XP, settings) stays. Lessons, review words and level
  /// results are swapped with that language's saved ones, or start empty.
  void switchCourse(String id) {
    final current = ref.read(activeCourseProvider);
    if (id == current || !isKnownLanguage(id)) return;
    final prefs = ref.read(prefsProvider);
    final (profile, course) = splitState(state.toJson());
    final stash = readStash(prefs);
    stash[current] = course;
    final next = stash.remove(id) ?? const <String, dynamic>{};
    writeStash(prefs, stash);
    final s = AppState.fromJson(mergeState(profile, next));
    ref.read(activeCourseProvider.notifier).set(id);
    _save(s);
    state = s;
  }

  // ---- hearts -------------------------------------------------------------------

  int get hearts => state.heartsAt(_now);

  /// Moves regenerated hearts into [AppState.hearts] and keeps the timer
  /// aligned, so a half-finished wait is never lost.
  void _bankHearts(AppState s, DateTime now) {
    final h = s.heartsAt(now);
    final gained = h - s.hearts;
    s.hearts = h;
    s.heartsStamp = h >= maxHearts
        ? 0
        : s.heartsStamp + gained * heartRegen.inMilliseconds;
  }

  void loseHeart() => _update((s) {
        final now = _now;
        _bankHearts(s, now);
        if (s.hearts <= 0) return;
        if (s.hearts >= maxHearts) s.heartsStamp = now.millisecondsSinceEpoch;
        s.hearts--;
      });

  void gainHeart() => _update((s) {
        _bankHearts(s, _now);
        s.hearts = (s.hearts + 1).clamp(0, maxHearts);
        if (s.hearts >= maxHearts) s.heartsStamp = 0;
      });

  /// Free refill for the hidden button in Settings.
  void refillHearts() => _update((s) {
        s.hearts = maxHearts;
        s.heartsStamp = 0;
      });

  bool refillHeartsWithGems() {
    if (state.gems < heartRefillGems || hearts >= maxHearts) return false;
    _update((s) {
      s.gems -= heartRefillGems;
      s.hearts = maxHearts;
      s.heartsStamp = 0;
    });
    return true;
  }

  // ---- shop ----------------------------------------------------------------------

  bool buyStreakFreeze() {
    if (state.gems < streakFreezeGems || state.freezes >= 2) return false;
    _update((s) {
      s.gems -= streakFreezeGems;
      s.freezes++;
    });
    return true;
  }

  bool buyXpBoost() {
    if (state.gems < xpBoostGems) return false;
    _update((s) {
      s.gems -= xpBoostGems;
      final base = s.boostActive(_now) ? s.xpBoostUntil : _now.millisecondsSinceEpoch;
      s.xpBoostUntil = base + xpBoostDuration.inMilliseconds;
    });
    return true;
  }

  // ---- finishing sessions ----------------------------------------------------------

  Reward finishSession(LessonResult r) {
    late Reward reward;
    _update((s) {
      _rollover(s);
      final now = _now;
      final today = dayKey(now);
      final goalBefore = s.xpOn(today) >= s.dailyGoalXp;

      // XP: base by kind, bonus for accuracy.
      var xp = switch (r.kind) {
        SessionKind.lesson => 10,
        SessionKind.practice => 8,
        SessionKind.story => 14,
        SessionKind.checkpoint => checkpointXp,
      };
      if (r.perfect) xp += 5;
      final boosted = s.boostActive(now);
      if (boosted) xp *= 2;
      s.xp += xp;
      s.xpByDay[today] = s.xpOn(today) + xp;

      // Gems.
      var gems = switch (r.kind) {
        SessionKind.lesson => 10,
        SessionKind.practice => 5,
        SessionKind.story => 8,
        SessionKind.checkpoint => 0,
      };
      if (r.perfect && r.kind != SessionKind.checkpoint) gems += 5;

      // A checkpoint is passed with enough correct answers. Gems only come
      // with the first pass, so retrying cannot farm them.
      final accuracy = r.total == 0 ? 0 : (r.correct * 100 / r.total).round();
      final isCheckpoint = r.kind == SessionKind.checkpoint && r.levelId != null;
      final passed = isCheckpoint && accuracy >= (checkpointPassMark * 100).round();
      if (isCheckpoint) {
        final level = r.levelId!;
        if ((s.checkpointBest[level] ?? 0) < accuracy) {
          s.checkpointBest[level] = accuracy;
        }
        if (passed && s.passedLevels.add(level)) gems += checkpointGems;
      }
      s.gems += gems;

      // Streak.
      final before = s.streakAt(now);
      final last = s.lastActiveDay;
      if (last != today) {
        if (last == null) {
          s.streak = 1;
        } else {
          final gap = daysBetween(last, today);
          if (gap == 1) {
            s.streak++;
          } else {
            final missed = gap - 1;
            if (s.freezes >= missed) {
              s.freezes -= missed;
              s.streak++;
            } else {
              s.streak = 1;
            }
          }
        }
        s.lastActiveDay = today;
        if (s.streak > s.longestStreak) s.longestStreak = s.streak;
      }

      // Lesson bookkeeping.
      if (r.kind == SessionKind.lesson && r.lessonId != null) {
        s.completedLessons.add(r.lessonId!);
        s.lessonRuns[r.lessonId!] = (s.lessonRuns[r.lessonId!] ?? 0) + 1;
        if (r.perfect) s.perfectLessons++;
      }
      if (r.kind == SessionKind.practice) {
        _bankHearts(s, now);
        s.hearts = (s.hearts + 1).clamp(0, maxHearts);
        if (s.hearts >= maxHearts) s.heartsStamp = 0;
      }

      // Spaced repetition.
      for (final id in r.correctWordIds.toSet()) {
        final box = ((s.wordBox[id] ?? 0) + 1).clamp(0, 5);
        s.wordBox[id] = box;
        s.wordDue[id] = dayKey(now.add(Duration(days: _boxIntervals[box])));
        if (box >= 2) s.mistakes.remove(id);
      }
      for (final id in r.wrongWordIds.toSet()) {
        s.wordBox[id] = ((s.wordBox[id] ?? 0) - 1).clamp(0, 5);
        s.wordDue[id] = today;
        s.mistakes.add(id);
      }
      s.wordsCorrect += r.correctWordIds.length;

      // Quests.
      void bump(QuestKind k, int by, {bool max = false}) {
        for (final q in questsForDay(today)) {
          if (q.kind != k) continue;
          final cur = s.questProgress[q.id] ?? 0;
          s.questProgress[q.id] = max ? (by > cur ? by : cur) : cur + by;
        }
      }

      bump(QuestKind.earnXp, xp);
      if (r.kind == SessionKind.lesson) bump(QuestKind.finishLessons, 1);
      if (r.perfect) bump(QuestKind.perfectLesson, 1);
      bump(QuestKind.learnWords, r.correctWordIds.length);
      bump(QuestKind.combo, r.maxCombo, max: true);

      final unlocked = _checkAchievements(s);
      reward = Reward(
        xp: xp,
        gems: gems,
        streak: s.streak,
        streakIncreased: s.streak > before,
        goalJustMet: !goalBefore && s.xpOn(today) >= s.dailyGoalXp,
        newAchievements: unlocked,
        boosted: boosted,
        checkpointLevel: isCheckpoint ? r.levelId : null,
        checkpointPassed: passed,
        accuracyPercent: accuracy,
      );
    });
    return reward;
  }

  void markStoryDone(String id) => _update((s) => s.storiesDone.add(id));

  // ---- quests & achievements -----------------------------------------------------------

  bool claimQuest(String id) {
    _update(_rollover);
    final q = questsForDay(dayKey(_now)).where((q) => q.id == id).firstOrNull;
    if (q == null) return false;
    if (state.questClaimed.contains(id)) return false;
    if ((state.questProgress[id] ?? 0) < q.target) return false;
    _update((s) {
      s.questClaimed.add(id);
      s.gems += q.gems;
    });
    return true;
  }

  bool claimAchievement(String id) {
    final def = achievementDefs.where((a) => a.id == id).firstOrNull;
    if (def == null ||
        !state.achievements.contains(id) ||
        state.achievementsClaimed.contains(id)) {
      return false;
    }
    _update((s) {
      s.achievementsClaimed.add(id);
      s.gems += def.gems;
    });
    return true;
  }

  List<String> _checkAchievements(AppState s) {
    final earned = <String>{
      if (s.completedLessons.isNotEmpty) 'first',
      if (s.completedLessons.length >= 10) 'lessons10',
      if (s.completedLessons.length >= 50) 'lessons50',
      if (s.longestStreak >= 3) 'streak3',
      if (s.longestStreak >= 7) 'streak7',
      if (s.longestStreak >= 30) 'streak30',
      if (s.xp >= 500) 'xp500',
      if (s.xp >= 5000) 'xp5000',
      if (s.perfectLessons >= 5) 'perfect5',
      if (s.wordsLearned >= 50) 'words50',
      if (s.storiesDone.length >= 3) 'stories3',
      for (final level in s.passedLevels) 'level$level',
    };
    final fresh = earned.difference(s.achievements).toList();
    s.achievements.addAll(earned);
    return fresh;
  }
}
