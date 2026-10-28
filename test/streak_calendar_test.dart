import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/dates.dart';
import 'package:multilingo/features/profile/streak_calendar.dart';
import 'package:multilingo/state/app_state.dart';

void main() {
  test('month grid starts on Monday and fills whole weeks', () {
    // March 2026 starts on a Sunday: six empty cells, then 31 days.
    final march = monthCells(2026, 3);
    expect(march.take(6), everyElement(isNull));
    expect(march[6], '2026-03-01');
    expect(march.whereType<String>().length, 31);
    expect(march.length % 7, 0);
    // February 2027 starts on a Monday and has 28 days: exactly four weeks.
    final feb = monthCells(2027, 2);
    expect(feb.first, '2027-02-01');
    expect(feb.length, 28);
    // Leap year.
    expect(monthCells(2028, 2).whereType<String>().length, 29);
    // December rolls over correctly.
    expect(monthCells(2026, 12).whereType<String>().last, '2026-12-31');
  });

  testWidgets('shows a flame on practised days and moves between months', (
    t,
  ) async {
    final s = AppState()
      ..xpByDay = {'2026-03-02': 20, '2026-03-03': 15, '2026-02-27': 10};
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StreakCalendar(state: s, now: DateTime(2026, 3, 10)),
          ),
        ),
      ),
    );
    expect(find.text('March 2026'), findsOneWidget);
    expect(find.text('2 active days'), findsOneWidget);
    // Cannot go forward from the current month.
    final next = find.byWidgetPredicate(
      (w) => w is IconButton && w.tooltip == 'Next month',
    );
    expect(t.widget<IconButton>(next).onPressed, isNull);

    await t.tap(find.byTooltip('Previous month'));
    await t.pump();
    expect(find.text('February 2026'), findsOneWidget);
    expect(find.text('1 active day'), findsOneWidget);
    // February is the first month with XP, so we cannot go further back.
    expect(
      t
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Previous month',
            ),
          )
          .onPressed,
      isNull,
    );
  });
}
