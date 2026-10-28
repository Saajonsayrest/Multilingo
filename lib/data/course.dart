import 'dart:math';

import '../domain/levels.dart';
import '../domain/models.dart';
import 'content/alphabet.dart' as alpha;
import 'content/content_a.dart';
import 'content/content_b.dart';
import 'content/content_c.dart';
import 'content/level_a2a.dart';
import 'content/level_a2b.dart';
import 'content/level_a2c.dart';
import 'content/level_b1a.dart';
import 'content/level_b1b.dart';
import 'content/level_b1c.dart';
import 'content/level_b2a.dart';
import 'content/level_b2b.dart';
import 'content/level_b2c.dart';
import 'content/level_c1a.dart';
import 'content/level_c1b.dart';
import 'content/level_c1c.dart';
import 'content/level_c2a.dart';
import 'content/level_c2b.dart';
import 'content/level_c2c.dart';
import 'content/stories.dart' as story;
import 'content_de/de_a1a.dart';
import 'content_de/de_a1b.dart';
import 'content_de/de_a1c.dart';
import 'content_de/de_a2a.dart';
import 'content_de/de_a2b.dart';
import 'content_de/de_a2c.dart';
import 'content_de/de_b1a.dart';
import 'content_de/de_b1b.dart';
import 'content_de/de_b1c.dart';
import 'content_de/de_b2a.dart';
import 'content_de/de_b2b.dart';
import 'content_de/de_b2c.dart';
import 'content_de/de_c1a.dart';
import 'content_de/de_c1b.dart';
import 'content_de/de_c1c.dart';
import 'content_de/de_c2a.dart';
import 'content_de/de_c2b.dart';
import 'content_de/de_c2c.dart';
import 'content_de/de_stories.dart';
import 'content_de/de_alphabet.dart';
import 'languages.dart';

/// One piece of a sentence for tap-a-word hints.
class HintPiece {
  const HintPiece(this.text, this.word);

  final String text;

  /// The course word this text matches, or null when the course does not teach it.
  final Word? word;
}

/// One whole course (Italian or German), A1 to C2, indexed for fast lookup.
/// Built once per language, the first time it is needed.
///
/// Rules:
/// - Lessons unlock one after another.
/// - A level's checkpoint opens when all its lessons are done.
/// - The first lesson of the next level opens when that checkpoint is passed.
///
/// In the content, [Word.it] and [Sentence.it] hold the language being
/// taught, whatever it is. The name is old.
class Course {
  Course._(this.language, this.units, this.stories, this.alphabet) {
    for (final u in units) {
      _unitsByLevel.putIfAbsent(u.level, () => []).add(u);
      for (final l in u.lessons) {
        _lessons[l.id] = l;
        _unitOf[l.id] = u;
        flatLessons.add(l);
        _lessonsByLevel.putIfAbsent(u.level, () => []).add(l);
        for (final w in l.words) {
          allWords.add(w);
          _words[w.id] = w;
          _byTarget.putIfAbsent(normalize(w.it), () => w);
        }
      }
    }
    levels = [
      for (final level in cefrLevels)
        if (_unitsByLevel.containsKey(level.id)) level,
    ];
  }

  /// The course for a language id. Unknown ids give the Italian course.
  static Course of(String id) {
    final lang = languageById(id);
    return _built.putIfAbsent(lang.id, () => _build(lang));
  }

  /// The Italian course. Kept for tests and code that has no language yet.
  static Course get instance => of(defaultLanguageId);

  static final Map<String, Course> _built = {};

  static Course _build(Language lang) => switch (lang.id) {
        'de' => Course._(
            lang,
            [
              ...deUnitsA1a,
              ...deUnitsA1b,
              ...deUnitsA1c,
              ...deUnitsA2a,
              ...deUnitsA2b,
              ...deUnitsA2c,
              ...deUnitsB1a,
              ...deUnitsB1b,
              ...deUnitsB1c,
              ...deUnitsB2a,
              ...deUnitsB2b,
              ...deUnitsB2c,
              ...deUnitsC1a,
              ...deUnitsC1b,
              ...deUnitsC1c,
              ...deUnitsC2a,
              ...deUnitsC2b,
              ...deUnitsC2c,
            ],
            deStories,
            deAlphabet,
          ),
        _ => Course._(
            lang,
            [
              ...unitsA,
              ...unitsB,
              ...unitsC,
              ...unitsA2a,
              ...unitsA2b,
              ...unitsA2c,
              ...unitsB1a,
              ...unitsB1b,
              ...unitsB1c,
              ...unitsB2a,
              ...unitsB2b,
              ...unitsB2c,
              ...unitsC1a,
              ...unitsC1b,
              ...unitsC1c,
              ...unitsC2a,
              ...unitsC2b,
              ...unitsC2c,
            ],
            story.stories,
            alpha.alphabet,
          ),
      };

  final Language language;
  final List<UnitDef> units;
  final List<StoryDef> stories;
  final List<AlphabetEntry> alphabet;

  /// CEFR levels that have content, in learning order.
  late final List<CefrLevel> levels;

  final List<LessonDef> flatLessons = [];
  final List<Word> allWords = [];
  final Map<String, LessonDef> _lessons = {};
  final Map<String, UnitDef> _unitOf = {};
  final Map<String, Word> _words = {};
  final Map<String, Word> _byTarget = {};
  final Map<String, List<UnitDef>> _unitsByLevel = {};
  final Map<String, List<LessonDef>> _lessonsByLevel = {};

  LessonDef lesson(String id) => _lessons[id]!;
  UnitDef unitOf(String lessonId) => _unitOf[lessonId]!;
  Word? word(String id) => _words[id];

  /// Splits a sentence in the language being learned into pieces, so every word (or short phrase
  /// like "come stai") the course teaches can show its meaning when tapped.
  /// Pieces keep their punctuation. [HintPiece.word] is null for unknown text.
  List<HintPiece> hintPieces(String sentence) {
    const longestPhrase = 3;
    final tokens = sentence.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final out = <HintPiece>[];
    var i = 0;
    while (i < tokens.length) {
      var take = 1;
      Word? found;
      for (var n = min(longestPhrase, tokens.length - i); n >= 1; n--) {
        final w = _byTarget[normalize(tokens.sublist(i, i + n).join(' '))];
        if (w != null) {
          take = n;
          found = w;
          break;
        }
      }
      out.add(HintPiece(tokens.sublist(i, i + take).join(' '), found));
      i += take;
    }
    return out;
  }

  String levelOf(String lessonId) => unitOf(lessonId).level;
  List<UnitDef> unitsOfLevel(String level) => _unitsByLevel[level] ?? const [];
  List<LessonDef> lessonsOfLevel(String level) =>
      _lessonsByLevel[level] ?? const [];

  /// The level before [level], or null for the first.
  String? previousLevel(String level) {
    final i = levels.indexWhere((l) => l.id == level);
    return i <= 0 ? null : levels[i - 1].id;
  }

  /// Index of the first lesson not yet completed, or the last lesson.
  int currentIndex(Set<String> completed) {
    final i = flatLessons.indexWhere((l) => !completed.contains(l.id));
    return i == -1 ? flatLessons.length - 1 : i;
  }

  /// Lessons finished in [level].
  int doneIn(String level, Set<String> completed) =>
      lessonsOfLevel(level).where((l) => completed.contains(l.id)).length;

  bool levelLessonsDone(String level, Set<String> completed) =>
      lessonsOfLevel(level).isNotEmpty &&
      doneIn(level, completed) == lessonsOfLevel(level).length;

  /// The checkpoint opens once every lesson of its level is done.
  bool checkpointReady(String level, Set<String> completed) =>
      levelLessonsDone(level, completed);

  bool isUnlocked(
    String lessonId,
    Set<String> completed,
    Set<String> passedLevels,
  ) {
    if (completed.contains(lessonId)) return true;
    final i = flatLessons.indexWhere((l) => l.id == lessonId);
    if (i == -1 || i > currentIndex(completed)) return false;
    final prev = previousLevel(levelOf(lessonId));
    return prev == null || passedLevels.contains(prev);
  }

  /// The level the learner is working on now.
  String currentLevel(Set<String> completed, Set<String> passedLevels) {
    for (final level in levels) {
      if (!passedLevels.contains(level.id)) return level.id;
    }
    return levels.last.id;
  }
}
