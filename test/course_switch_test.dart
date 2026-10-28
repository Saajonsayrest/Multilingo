import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/state/controller.dart';
import 'package:multilingo/state/course_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> boot() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  var tick = 0;
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(
      () => DateTime(2026, 3, 2, 10).add(Duration(minutes: tick++)),
    ),
  ]);
  addTearDown(c.dispose);
  c.read(appProvider.notifier).completeOnboarding(
      name: 'Tester', dailyGoalXp: 20, level: 'beginner');
  return c;
}

LessonResult done(String id) => LessonResult(
      lessonId: id,
      correct: 10,
      total: 10,
      correctWordIds: [Course.of(id.startsWith('de_') ? 'de' : 'it').lesson(id).words.first.id],
    );

void main() {
  test('Italian is the default course', () async {
    final c = await boot();
    expect(c.read(activeCourseProvider), 'it');
    expect(c.read(courseProvider).language.id, 'it');
  });

  test('each language keeps its own lessons, the profile is shared', () async {
    final c = await boot();
    final ctrl = c.read(appProvider.notifier);
    final itLesson = Course.of('it').flatLessons.first.id;
    final deLesson = Course.of('de').flatLessons.first.id;

    ctrl.finishSession(done(itLesson));
    final xpAfterItalian = c.read(appProvider).xp;
    expect(c.read(appProvider).completedLessons, {itLesson});

    ctrl.switchCourse('de');
    expect(c.read(activeCourseProvider), 'de');
    expect(c.read(courseProvider).language.id, 'de');
    var s = c.read(appProvider);
    expect(s.completedLessons, isEmpty, reason: 'German starts fresh');
    expect(s.xp, xpAfterItalian, reason: 'XP is shared');
    expect(s.name, 'Tester');
    expect(s.onboarded, isTrue);

    ctrl.finishSession(done(deLesson));
    expect(c.read(appProvider).completedLessons, {deLesson});

    ctrl.switchCourse('it');
    s = c.read(appProvider);
    expect(s.completedLessons, {itLesson}, reason: 'Italian progress came back');
    expect(s.xp, greaterThan(xpAfterItalian), reason: 'the German lesson gave XP');

    ctrl.switchCourse('de');
    expect(c.read(appProvider).completedLessons, {deLesson});
  });

  test('the choice survives an app restart', () async {
    final c = await boot();
    c.read(appProvider.notifier).switchCourse('de');
    final prefs = c.read(prefsProvider);

    final c2 = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
    addTearDown(c2.dispose);
    expect(c2.read(activeCourseProvider), 'de');
    expect(c2.read(appProvider).onboarded, isTrue);
  });

  test('an unknown course id is ignored', () async {
    final c = await boot();
    c.read(appProvider.notifier).switchCourse('xx');
    expect(c.read(activeCourseProvider), 'it');
  });

  test('reset wipes every language', () async {
    final c = await boot();
    final ctrl = c.read(appProvider.notifier);
    ctrl.finishSession(done(Course.of('it').flatLessons.first.id));
    ctrl.switchCourse('de');
    ctrl.resetAll();
    ctrl.switchCourse('it');
    expect(c.read(appProvider).completedLessons, isEmpty);
  });
}
