import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/core/widgets.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/domain/exercise_generator.dart';
import 'package:multilingo/features/lesson/lesson_screen.dart';
import 'package:multilingo/main.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tears the app down so the 4 second auto-save timer cannot outlive the test.
Future<void> finish(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MultilingoApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('onboarding leads to the learning path', (tester) async {
    final c = await pumpApp(tester);
    expect(find.text('Ciao! I am Pip.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Tester');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(BigButton));
      // The home path pulses forever, so pumpAndSettle would never finish.
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(c.read(appProvider).onboarded, isTrue);
    expect(c.read(appProvider).name, 'Tester');
    expect(find.text('Basics'), findsOneWidget);
    expect(find.text('Learn'), findsWidgets);
    await finish(tester, c);
  });

  testWidgets('a full lesson can be completed by answering correctly', (tester) async {
    final c = await pumpApp(tester);
    c.read(appProvider.notifier).completeOnboarding(
        name: 'T', dailyGoalXp: 20, level: 'beginner');
    await tester.pump(const Duration(milliseconds: 500));

    final lesson = Course.instance.flatLessons.first;
    final gen = ExerciseGenerator(allWords: Course.instance.allWords);
    final exercises = gen.forLesson(lesson);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: LessonScreen(
              title: lesson.title, exercises: exercises, lessonId: lesson.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The lesson opens with a new word card, not a question.
    expect(find.text('New word'), findsOneWidget);
    expect(find.text('CHECK'), findsNothing);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await finish(tester, c);
  });
}
