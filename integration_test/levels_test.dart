import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/main.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Finishes all A1 lessons, then shows the A1 checkpoint and the Profile
/// level card on a real device or simulator.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('levels and checkpoint on device', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
    final n = c.read(appProvider.notifier);
    n.completeOnboarding(name: 'Sajon', dailyGoalXp: 20, level: 'beginner');
    for (final l in Course.instance.lessonsOfLevel('A1')) {
      n.finishSession(LessonResult(
        lessonId: l.id,
        correct: 10,
        total: 10,
        correctWordIds: l.words.map((w) => w.id).toList(),
      ));
    }
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const MultilingoApp()));
    await t.pump(const Duration(seconds: 2));

    // Top of the path: level banner.
    await t.pump(const Duration(seconds: 3));

    // Scroll to the A1 checkpoint card.
    await t.scrollUntilVisible(find.text('A1 Checkpoint'), 400,
        scrollable: find.byType(Scrollable).first);
    await t.pump(const Duration(seconds: 3));
    expect(find.text('START CHECKPOINT'), findsOneWidget);

    // Profile: levels card.
    await t.tap(find.byIcon(Icons.person_rounded).last);
    await t.pump(const Duration(seconds: 2));
    await t.scrollUntilVisible(find.text('Your Italian level'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.pump(const Duration(seconds: 3));

    await t.pumpWidget(const SizedBox());
    c.dispose();
  });
}
