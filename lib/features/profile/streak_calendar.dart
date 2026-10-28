import 'package:flutter/material.dart';

import '../../core/symbols.dart';
import '../../core/theme.dart';
import '../../domain/dates.dart';
import '../../state/app_state.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December',
];
const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A month grid like the one in Duolingo: a flame on every day the learner
/// earned XP, a ring on today. Arrows move between months.
class StreakCalendar extends StatefulWidget {
  const StreakCalendar({super.key, required this.state, required this.now});

  final AppState state;
  final DateTime now;

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late int _year = widget.now.year;
  late int _month = widget.now.month;

  void _move(int delta) {
    final d = DateTime(_year, _month + delta);
    setState(() {
      _year = d.year;
      _month = d.month;
    });
  }

  /// Nothing to see before the first day with XP, so stop going back there.
  bool get _canGoBack {
    final days = widget.state.xpByDay.entries.where((e) => e.value > 0).map((e) => e.key);
    if (days.isEmpty) return false;
    final first = days.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    final f = parseDayKey(first);
    return DateTime(_year, _month).isAfter(DateTime(f.year, f.month));
  }

  bool get _canGoForward =>
      DateTime(_year, _month).isBefore(DateTime(widget.now.year, widget.now.month));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dayKey(widget.now);
    final cells = monthCells(_year, _month);
    final activeThisMonth = [
      for (final c in cells)
        if (c != null && widget.state.xpOn(c) > 0) c,
    ].length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _canGoBack ? () => _move(-1) : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_months[_month - 1]} $_year',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '$activeThisMonth active ${activeThisMonth == 1 ? 'day' : 'days'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _canGoForward ? () => _move(1) : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final l in _dayLetters)
                  Expanded(
                    child: Center(
                      child: Text(l,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var row = 0; row < cells.length ~/ 7; row++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(child: _cell(context, cells[row * 7 + col], today)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String? key, String today) {
    if (key == null) return const SizedBox(height: 40);
    final day = int.parse(key.substring(8));
    final active = widget.state.xpOn(key) > 0;
    final isToday = key == today;
    final future = key.compareTo(today) > 0;
    final theme = Theme.of(context);
    return Semantics(
      label: '$day, ${active ? 'practised' : future ? 'upcoming' : 'no practice'}',
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Palette.lemon.withValues(alpha: 0.35) : null,
          border: isToday ? Border.all(color: Palette.tomato, width: 2) : null,
        ),
        child: Center(
          child: active
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    const GlyphIcon(Glyph.streak, size: 30),
                    Positioned(
                      bottom: 0,
                      child: Text('$day',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ],
                )
              : Text(
                  '$day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: future ? theme.hintColor.withValues(alpha: 0.5) : null,
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
