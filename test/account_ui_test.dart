import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/cloud_save.dart';
import 'package:multilingo/features/settings/account_screen.dart';
import 'package:multilingo/l10n/app_localizations.dart';
import 'package:multilingo/state/cloud_sync.dart';
import 'package:multilingo/state/controller.dart';

import 'support/cloud_fakes.dart';

const _email = 'learner@example.com';
const _pw = 'correct-horse';

void main() {
  late FakeAuthServer server;
  late MemoryCloudStore store;

  setUp(() {
    server = FakeAuthServer();
    store = MemoryCloudStore();
    Phone.now = DateTime(2026, 3, 2, 10);
  });

  Future<Phone> bootPhone(
    WidgetTester t, {
    bool onboarded = true,
    bool cloud = true,
  }) async {
    final p = await t.runAsync(() =>
        Phone.boot(server: server, store: store, onboarded: onboarded, cloud: cloud));
    return p!;
  }

  Future<void> show(
    WidgetTester t,
    Phone p, {
    Locale locale = const Locale('en'),
    Widget screen = const AccountScreen(),
  }) async {
    // A tall screen, so lists are not clipped.
    t.view.physicalSize = const Size(800, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(UncontrolledProviderScope(
      container: p.container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConflictHost(child: screen),
      ),
    ));
    await t.pump();
  }

  Future<void> settle(WidgetTester t, Phone p) async {
    await t.runAsync(p.settle);
    await t.pump();
    await t.pump();
  }

  testWidgets('a silent account shows its status and the form to add an email', (t) async {
    final p = await bootPhone(t);
    await show(t, p);
    expect(find.textContaining('Saved to the cloud'), findsOneWidget);
    expect(find.byKey(const Key('account-email')), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsNothing);
  });

  testWidgets('a weak password or a bad email is refused before anything is sent', (t) async {
    final p = await bootPhone(t);
    await show(t, p);
    await t.enterText(find.byKey(const Key('account-email')), 'not-an-email');
    await t.enterText(find.byKey(const Key('account-password')), 'longenough');
    await t.tap(find.text('CREATE ACCOUNT'));
    await settle(t, p);
    expect(find.text('That email address does not look right.'), findsOneWidget);

    await t.enterText(find.byKey(const Key('account-email')), _email);
    await t.enterText(find.byKey(const Key('account-password')), 'short');
    await t.tap(find.text('CREATE ACCOUNT'));
    await settle(t, p);
    expect(find.text('Use a password with at least 8 characters.'), findsOneWidget);
    expect(server.passwords, isEmpty);
  });

  testWidgets('creating an account keeps the progress and shows the email', (t) async {
    final p = await bootPhone(t);
    await show(t, p);
    await t.enterText(find.byKey(const Key('account-email')), _email);
    await t.enterText(find.byKey(const Key('account-password')), _pw);
    await t.tap(find.text('CREATE ACCOUNT'));
    await settle(t, p);
    expect(find.text('Signed in as $_email'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
    expect(find.byKey(const Key('account-email')), findsNothing);
  });

  testWidgets('an email that already has an account says so', (t) async {
    server.passwords[_email] = _pw;
    server.uidByEmail[_email] = 'someone-else';
    final p = await bootPhone(t);
    await show(t, p);
    await t.enterText(find.byKey(const Key('account-email')), _email);
    await t.enterText(find.byKey(const Key('account-password')), _pw);
    await t.tap(find.text('CREATE ACCOUNT'));
    await settle(t, p);
    expect(find.text('This email already has an account. Use Sign in instead.'),
        findsOneWidget);
  });

  testWidgets('offline, the status says progress is safe on the phone', (t) async {
    final p = await bootPhone(t);
    await show(t, p);
    store.offline = true;
    await t.runAsync(() => p.doLessons(1));
    await t.pump();
    expect(find.textContaining('No connection'), findsOneWidget);
    expect(find.text('SAVE NOW'), findsOneWidget);
  });

  testWidgets('a restore point can be restored after a confirmation', (t) async {
    final p = await bootPhone(t);
    await t.runAsync(() => p.doLessons(5));
    final point = (await t.runAsync(p.sync.loadCheckpoints))!.firstWhere(
      (c) => c.reason == CheckpointReason.milestone && summarize(c.save).lessons == 5,
    );
    await t.runAsync(() => p.doLessons(2));
    await show(t, p);
    await settle(t, p);
    expect(find.text('Restore'), findsWidgets);

    // The first row is the newest point. Restore the one that holds 5 lessons.
    final tile = find.ancestor(
      of: find.textContaining('5 lessons'),
      matching: find.byType(ListTile),
    );
    expect(tile, findsWidgets);
    await t.tap(find.descendant(of: tile.first, matching: find.text('Restore')));
    await t.pumpAndSettle();
    expect(find.text('Restore this copy?'), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Restore'));
    await settle(t, p);
    expect(find.text('Progress restored.'), findsOneWidget);
    expect(p.container.read(appProvider).completedLessons, hasLength(5));
    expect(point.slot, isNonNegative);
  });

  testWidgets('both copies changed: the choice dialog opens by itself', (t) async {
    final a = await bootPhone(t);
    await t.runAsync(() => a.sync.createAccount(_email, _pw));
    await t.runAsync(() => a.doLessons(4));

    final b = await bootPhone(t);
    await t.runAsync(() => b.doLessons(1));
    await show(t, b);
    await t.runAsync(() => b.sync.signIn(_email, _pw));
    await settle(t, b);
    await t.pumpAndSettle();
    expect(find.text('Which progress do you want to keep?'), findsOneWidget);
    expect(find.text('This phone'), findsOneWidget);
    expect(find.text('Your account'), findsOneWidget);

    await t.tap(find.text('Use the account progress'));
    await settle(t, b);
    await t.pumpAndSettle();
    expect(find.text('Which progress do you want to keep?'), findsNothing);
    expect(b.container.read(appProvider).completedLessons, hasLength(4));
  });

  testWidgets('"decide later" closes the dialog and the account screen offers it again', (t) async {
    final a = await bootPhone(t);
    await t.runAsync(() => a.sync.createAccount(_email, _pw));
    await t.runAsync(() => a.doLessons(2));

    final b = await bootPhone(t);
    await show(t, b);
    await t.runAsync(() => b.sync.signIn(_email, _pw));
    await settle(t, b);
    await t.pumpAndSettle();
    await t.tap(find.text('Decide later'));
    await t.pumpAndSettle();
    expect(find.text('Which progress do you want to keep?'), findsNothing);
    expect(b.status.phase, SyncPhase.conflict, reason: 'nothing was decided');
    expect(find.text('CHOOSE'), findsOneWidget);

    await t.tap(find.text('CHOOSE'));
    await t.pumpAndSettle();
    expect(find.text('Which progress do you want to keep?'), findsOneWidget);
  });

  testWidgets('signing in with a wrong password shows a message and stays', (t) async {
    final a = await bootPhone(t);
    await t.runAsync(() => a.sync.createAccount(_email, _pw));
    final b = await bootPhone(t, onboarded: false);
    await show(t, b, screen: const SignInScreen());
    await t.enterText(find.byKey(const Key('signin-email')), _email);
    await t.enterText(find.byKey(const Key('signin-password')), 'wrong-password');
    await t.tap(find.text('SIGN IN'));
    await settle(t, b);
    expect(find.text('The email or the password is wrong.'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('a new phone signs in and gets the progress', (t) async {
    final a = await bootPhone(t);
    await t.runAsync(() => a.sync.createAccount(_email, _pw));
    await t.runAsync(() => a.doLessons(3));

    final b = await bootPhone(t, onboarded: false);
    await show(t, b, screen: const SignInScreen());
    await t.enterText(find.byKey(const Key('signin-email')), _email);
    await t.enterText(find.byKey(const Key('signin-password')), _pw);
    await t.tap(find.text('SIGN IN'));
    await settle(t, b);
    expect(b.container.read(appProvider).onboarded, isTrue);
    expect(b.container.read(appProvider).completedLessons, hasLength(3));
  });

  testWidgets('the screen follows the phone language', (t) async {
    final p = await bootPhone(t);
    await show(t, p, locale: const Locale('it'));
    expect(find.text('Account e salvataggio nel cloud'), findsOneWidget);
    expect(find.text('CREA ACCOUNT'), findsOneWidget);
  });

  testWidgets('a build without Firebase says so and offers no sign-in', (t) async {
    final p = await bootPhone(t, cloud: false);
    await show(t, p);
    expect(find.textContaining('not available in this build'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsNothing);
    expect(find.text('SAVE NOW'), findsNothing);
  });
}
