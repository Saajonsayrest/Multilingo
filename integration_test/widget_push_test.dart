import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:multilingo/state/controller.dart';
import 'package:multilingo/state/widget_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On a real Android device or emulator: finish one lesson, then push the
/// numbers to the home-screen widgets. Look at the home screen afterwards.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('push widget data', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
    final n = c.read(appProvider.notifier);
    n.completeOnboarding(name: 'Tester', dailyGoalXp: 30, level: 'beginner');
    n.finishSession(const LessonResult(
      lessonId: 'u1l1',
      correct: 10,
      total: 10,
      correctWordIds: ['u1l1w1'],
    ));
    await c.read(widgetSyncProvider).push();
    c.dispose();
  });
}
