import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/core/recognizer.dart';
import 'package:multilingo/domain/models.dart';
import 'package:multilingo/features/lesson/exercise_widgets.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A recogniser that "hears" whatever the test says.
class FakeRecognizer implements Recognizer {
  FakeRecognizer({this.available = true});

  final bool available;
  String? lastLocale;
  void Function(String, bool)? _result;
  int stops = 0;

  @override
  Future<bool> start({
    required String locale,
    required void Function(String words, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {
    lastLocale = locale;
    _result = onResult;
    return available;
  }

  void hear(String words, {bool isFinal = true}) => _result!(words, isFinal);

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> cancel() async {}
}

const speakExercise = Exercise(
  type: ExerciseType.speak,
  prompt: 'Guten Morgen, wie geht es dir?',
  answer: 'Guten Morgen, wie geht es dir?',
  audioText: 'Guten Morgen, wie geht es dir?',
  hint: 'Good morning, how are you?',
);

Future<(List<String?>, FakeRecognizer, ProviderContainer)> pump(
  WidgetTester t, {
  bool available = true,
  String course = 'it',
}) async {
  SharedPreferences.setMockInitialValues({'multilingo.activeCourse.v1': course});
  final prefs = await SharedPreferences.getInstance();
  final fake = FakeRecognizer(available: available);
  final answers = <String?>[];
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    recognizerProvider.overrideWithValue(fake),
  ]);
  addTearDown(c.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      home: Scaffold(
        body: ExerciseBody(
          exercise: speakExercise,
          onChanged: answers.add,
          onMistake: () {},
          locked: false,
        ),
      ),
    ),
  ));
  await t.pump();
  return (answers, fake, c);
}

void main() {
  testWidgets('saying the phrase correctly passes the exercise', (t) async {
    final (answers, fake, _) = await pump(t, course: 'de');
    await t.tap(find.byTooltip('Speak'));
    await t.pumpAndSettle();
    expect(fake.lastLocale, 'de-DE', reason: 'listens in the language being learned');
    expect(find.text('Listening... say the phrase now'), findsOneWidget);

    fake.hear('guten morgen wie geht es dir');
    await t.pump();
    expect(answers.last, speakExercise.answer);
    expect(find.textContaining('I heard: "guten morgen wie geht es dir"'), findsOneWidget);
    expect(find.text('I said it ✓'), findsOneWidget);
  });

  testWidgets('a wrong phrase is refused and can be tried again', (t) async {
    final (answers, fake, _) = await pump(t);
    await t.tap(find.byTooltip('Speak'));
    await t.pumpAndSettle();
    fake.hear('hello banana', isFinal: true);
    await t.pump();
    expect(answers.last, isNull);
    expect(find.text('Not quite. Listen once more, then try again.'), findsOneWidget);

    // Try again and get it right.
    await t.tap(find.byTooltip('Speak'));
    await t.pumpAndSettle();
    fake.hear('Guten Morgen, wie geht es dir?');
    await t.pump();
    expect(answers.last, speakExercise.answer);
  });

  testWidgets('partial words show while speaking but do not grade yet', (t) async {
    final (answers, fake, _) = await pump(t);
    await t.tap(find.byTooltip('Speak'));
    await t.pumpAndSettle();
    fake.hear('guten morgen', isFinal: false);
    await t.pump();
    expect(find.textContaining('I heard: "guten morgen"'), findsOneWidget);
    expect(answers, isEmpty);
  });

  testWidgets('no microphone: a clear message, and the fallback still works', (t) async {
    final (answers, _, _) = await pump(t, available: false);
    await t.tap(find.byTooltip('Speak'));
    await t.pumpAndSettle();
    expect(find.textContaining('The microphone is not available'), findsOneWidget);
    expect(answers, isEmpty);

    await t.tap(find.text('I said it out loud'));
    await t.pump();
    expect(answers.last, speakExercise.answer);
  });

  test('locale picking prefers the exact locale, then the language', () {
    expect(pickLocale(['en_US', 'de_AT', 'de_DE'], 'de-DE'), 'de_DE');
    expect(pickLocale(['en_US', 'de_AT'], 'de-DE'), 'de_AT');
    expect(pickLocale(['it-IT', 'en-US'], 'it-IT'), 'it-IT');
    expect(pickLocale(['en_US'], 'it-IT'), isNull);
    expect(pickLocale([], 'de-DE'), isNull);
  });
}
