import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/l10n/app_localizations.dart';
import 'package:multilingo/features/settings/settings_screen.dart';
import 'package:multilingo/state/app_state.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('seven taps on the version line refill all hearts', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    final ctrl = c.read(appProvider.notifier);
    for (var i = 0; i < maxHearts; i++) {
      ctrl.loseHeart();
    }
    expect(ctrl.hearts, 0);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    final footer = find.textContaining('Multilingo 1.0');
    await tester.scrollUntilVisible(footer, 200);

    for (var i = 0; i < 6; i++) {
      await tester.tap(footer);
    }
    expect(ctrl.hearts, 0, reason: 'six taps are not enough');

    await tester.tap(footer);
    await tester.pump();
    expect(ctrl.hearts, maxHearts);
    expect(c.read(appProvider).heartsStamp, 0);
    expect(find.text('Hearts refilled'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
