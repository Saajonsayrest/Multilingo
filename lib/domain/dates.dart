String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String k) {
  final p = k.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// Whole calendar days from [a] to [b] (b later = positive).
int daysBetween(String a, String b) =>
    parseDayKey(b).difference(parseDayKey(a)).inDays;

/// Monday of the week that contains [d], as a day key.
String weekKey(DateTime d) {
  final monday = DateTime.utc(d.year, d.month, d.day)
      .subtract(Duration(days: d.weekday - 1));
  return dayKey(monday);
}

/// The cells of a Monday-first month grid: nulls for the empty cells before
/// the 1st, then one day key per day. The length is always a whole number of
/// weeks, so the grid has straight rows.
List<String?> monthCells(int year, int month) {
  final first = DateTime.utc(year, month, 1);
  final days = DateTime.utc(year, month + 1, 0).day;
  final cells = <String?>[
    for (var i = 0; i < first.weekday - 1; i++) null,
    for (var d = 1; d <= days; d++) dayKey(DateTime.utc(year, month, d)),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}
