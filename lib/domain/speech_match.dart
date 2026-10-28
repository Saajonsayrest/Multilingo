import 'models.dart';

/// How well [heard] (what the phone's speech recognition understood) matches
/// [expected] (the phrase the learner should say). 0.0 to 1.0.
///
/// Speech recognition is never perfect, so this is forgiving: case, accents,
/// punctuation and word order inside the phrase are ignored, and one wrong
/// letter in a longer word still counts as the word.
double speechMatch(String heard, String expected) {
  final want = tokenize(normalize(expected));
  if (want.isEmpty) return 0;
  final have = tokenize(normalize(heard));
  if (have.isEmpty) return 0;
  final pool = List<String>.of(have);
  var hits = 0;
  for (final w in want) {
    final i = pool.indexWhere((h) => _sameWord(h, w));
    if (i != -1) {
      hits++;
      pool.removeAt(i);
    }
  }
  // Extra words the recogniser added count against the score a little.
  final extra = (have.length - hits).clamp(0, have.length);
  final score = hits / want.length - 0.05 * extra;
  return score.clamp(0.0, 1.0);
}

/// Share of the phrase that must be understood to count as correct.
const speechPassMark = 0.7;

bool speechPasses(String heard, String expected) =>
    speechMatch(heard, expected) >= speechPassMark;

bool _sameWord(String a, String b) {
  if (a == b) return true;
  if (a.length < 5 || b.length < 5) return false;
  return _distance(a, b) <= 1;
}

/// Levenshtein distance, stopping early once it is clearly above 1.
int _distance(String a, String b) {
  if ((a.length - b.length).abs() > 1) return 2;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost]
          .reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}
