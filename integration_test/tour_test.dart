import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:multilingo/core/widgets.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/domain/exercise_generator.dart';
import 'package:multilingo/domain/models.dart';
import 'package:multilingo/features/lesson/lesson_screen.dart';
import 'package:multilingo/main.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Slow, visible walk through the whole app so a person can watch it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> look(WidgetTester t, [int ms = 1500]) =>
      t.pump(Duration(milliseconds: ms));

  /// Answers one exercise correctly, using the known answer.
  Future<void> solve(WidgetTester t, Exercise e) async {
    switch (e.type) {
      case ExerciseType.multipleChoice ||
            ExerciseType.pictureSelect ||
            ExerciseType.listenSelect ||
            ExerciseType.fillGap:
        await t.tap(find.text(e.answer).last);
      case ExerciseType.translateToEn || ExerciseType.translateToIt:
        for (final token in e.answer.split(' ')) {
          final bank = find.descendant(
            of: find.byWidgetPredicate((w) => w is Opacity && w.opacity == 1),
            matching: find.text(token),
          );
          await t.tap(bank.first);
          await t.pump(const Duration(milliseconds: 350));
        }
      case ExerciseType.matchPairs:
        for (final p in e.pairs) {
          await t.tap(find.text(p[0]).first);
          await t.pump(const Duration(milliseconds: 250));
          await t.tap(find.text(p[1]).first);
          await t.pump(const Duration(milliseconds: 450));
        }
      case ExerciseType.listenType:
        await t.enterText(find.byType(TextField), e.answer);
      case ExerciseType.speak:
        await t.tap(find.text('I said it out loud'));
      case ExerciseType.teach:
        // A new word card has no Check step, only Continue.
        await look(t, 700);
        await t.tap(find.byType(BigButton).last);
        await look(t, 600);
        return;
    }
    await look(t, 700);
    await t.tap(find.byType(BigButton).last); // Check
    await look(t, 1100);
    await t.tap(find.byType(BigButton).last); // Continue
    await look(t, 600);
  }

  testWidgets('guided tour', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const MultilingoApp(),
    ));
    await look(t);

    await t.enterText(find.byType(TextField), 'Sajon');
    await look(t);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byType(BigButton));
      await look(t);
    }

    // Path, then a real lesson with known answers.
    await look(t);
    final lesson = Course.instance.flatLessons.first;
    final exercises = ExerciseGenerator(
      allWords: Course.instance.allWords,
      random: Random(7),
    ).forLesson(lesson);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => LessonScreen(
        title: lesson.title,
        exercises: exercises,
        lessonId: lesson.id,
      ),
    ));
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(LessonScreen), findsOneWidget);
    for (final e in exercises) {
      await solve(t, e);
    }
    await look(t, 3500); // reward screen
    await t.tap(find.byType(BigButton).last);
    await look(t, 2500);

    // Every tab, then the extra screens from the Practice hub.
    for (final icon in [
      Icons.fitness_center_rounded,
      Icons.emoji_events_rounded,
      Icons.flag_rounded,
      Icons.person_rounded,
    ]) {
      await t.tap(find.byIcon(icon).last);
      await look(t, 2500);
    }
    await t.tap(find.byIcon(Icons.settings_rounded).first);
    await look(t, 2500);
    await t.pageBack();
    await look(t, 800);
    await t.tap(find.byIcon(Icons.fitness_center_rounded).last);
    await look(t, 1200);
    for (final label in ['Stories', 'Sounds and letters', 'Shop']) {
      await t.tap(find.text(label));
      await look(t, 2500);
      await t.pageBack();
      await look(t, 800);
    }
  });
}
