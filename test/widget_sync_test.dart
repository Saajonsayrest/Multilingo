import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/state/app_state.dart';
import 'package:multilingo/state/widget_sync.dart';

void main() {
  final now = DateTime(2026, 3, 2, 10);

  test('new learner: sleeping Pip and the first lesson', () {
    final snap = WidgetSnapshot.of(AppState(), now);
    expect(snap.streak, 0);
    expect(snap.mood, 'sleeping');
    expect(snap.nextTitle, Course.instance.flatLessons.first.title);
    expect(snap.nextDetail, contains('A1'));
  });

  test('active today but goal not met: happy', () {
    final s = AppState()
      ..streak = 3
      ..lastActiveDay = '2026-03-02'
      ..xpByDay = {'2026-03-02': 10};
    final snap = WidgetSnapshot.of(s, now);
    expect(snap.mood, 'happy');
    expect(snap.todayXp, 10);
    expect(snap.streak, 3);
  });

  test('goal met: celebrating', () {
    final s = AppState()
      ..streak = 3
      ..lastActiveDay = '2026-03-02'
      ..dailyGoalXp = 20
      ..xpByDay = {'2026-03-02': 25};
    expect(WidgetSnapshot.of(s, now).mood, 'celebrating');
  });

  test('streak at risk: encouraging, mentions the streak', () {
    final s = AppState()
      ..streak = 5
      ..lastActiveDay = '2026-03-01';
    final snap = WidgetSnapshot.of(s, now);
    expect(snap.mood, 'encouraging');
    expect(snap.message, contains('5'));
  });

  test('finished level shows the checkpoint instead of a lesson', () {
    final a1 = Course.instance.lessonsOfLevel('A1').map((l) => l.id).toSet();
    final snap = WidgetSnapshot.of(AppState()..completedLessons = a1, now);
    expect(snap.nextTitle, 'A1 checkpoint');
  });

  test('values are plain types the native side can read', () {
    final map = WidgetSnapshot.of(AppState(), now).toMap();
    for (final v in map.values) {
      expect(v is int || v is String, isTrue);
    }
    expect(map.keys, containsAll(['streak', 'goal_xp', 'today_xp', 'mood', 'message', 'next_title', 'next_detail']));
  });
}
