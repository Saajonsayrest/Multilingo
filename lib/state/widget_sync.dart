import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../data/course.dart';
import '../domain/dates.dart';
import 'app_state.dart';
import 'controller.dart';
import 'course_state.dart';

const _providers = [
  'io.rea.multilingo.StreakWidgetProvider',
  'io.rea.multilingo.GoalWidgetProvider',
  'io.rea.multilingo.NextLessonWidgetProvider',
];

/// The plain values a widget shows. Pure, so it can be tested.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.streak,
    required this.goalXp,
    required this.todayXp,
    required this.weekXp,
    required this.wordsToReview,
    required this.mood,
    required this.message,
    required this.nextTitle,
    required this.nextDetail,
  });

  final int streak;
  final int goalXp;
  final int todayXp;
  final int weekXp;
  final int wordsToReview;

  /// Which Pip picture to show: celebrating, happy, encouraging or sleeping.
  final String mood;
  final String message;
  final String nextTitle;
  final String nextDetail;

  Map<String, Object> toMap() => {
        'streak': streak,
        'goal_xp': goalXp,
        'today_xp': todayXp,
        'week_xp': weekXp,
        'words_to_review': wordsToReview,
        'mood': mood,
        'message': message,
        'next_title': nextTitle,
        'next_detail': nextDetail,
      };

  static WidgetSnapshot of(AppState s, DateTime now, {Course? course}) {
    course ??= Course.instance;
    final today = s.xpOn(dayKey(now));
    final streak = s.streakAt(now);
    final goalMet = today >= s.dailyGoalXp;
    final active = s.activeToday(now);

    final String mood;
    final String message;
    if (goalMet) {
      mood = 'celebrating';
      message = 'Goal reached. Well done!';
    } else if (active) {
      mood = 'happy';
      message = 'Keep going, you are close.';
    } else if (streak > 0) {
      mood = 'encouraging';
      message = 'Practise today to keep your $streak day streak.';
    } else {
      mood = 'sleeping';
      message = 'Ready for a short lesson?';
    }

    final level = course.currentLevel(s.completedLessons, s.passedLevels);
    final String title;
    final String detail;
    if (course.checkpointReady(level, s.completedLessons) &&
        !s.passedLevels.contains(level)) {
      title = '$level checkpoint';
      detail = 'Pass it to open the next level';
    } else {
      final lesson = course.flatLessons[course.currentIndex(s.completedLessons)];
      final unit = course.unitOf(lesson.id);
      final number = unit.lessons.indexWhere((l) => l.id == lesson.id) + 1;
      title = lesson.title;
      detail = '${unit.title}, lesson $number of ${unit.lessons.length} (${unit.level})';
    }

    return WidgetSnapshot(
      streak: streak,
      goalXp: s.dailyGoalXp,
      todayXp: today,
      weekXp: s.weekXp(now),
      wordsToReview: s.dueWordIds(now).length,
      mood: mood,
      message: message,
      nextTitle: title,
      nextDetail: detail,
    );
  }
}

final widgetSyncProvider = Provider<WidgetSync>((ref) {
  final sync = WidgetSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});

/// Pushes the latest numbers to the home-screen widgets. Safe to call on any
/// platform: where widgets do not exist the calls are ignored.
class WidgetSync {
  WidgetSync(this._ref);

  final Ref _ref;
  Timer? _debounce;

  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), push);
  }

  Future<void> push() async {
    final snapshot = WidgetSnapshot.of(
      _ref.read(appProvider),
      _ref.read(clockProvider)(),
      course: _ref.read(courseProvider),
    );
    try {
      for (final e in snapshot.toMap().entries) {
        await HomeWidget.saveWidgetData<Object>(e.key, e.value);
      }
      for (final name in _providers) {
        await HomeWidget.updateWidget(qualifiedAndroidName: name);
      }
    } catch (_) {
      // No widget support here (iOS without an extension, tests, desktop).
    }
  }

  void dispose() => _debounce?.cancel();
}
