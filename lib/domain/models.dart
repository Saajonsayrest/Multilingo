/// Pure content and exercise models. No Flutter imports.
library;

/// A vocabulary item. [id] is stable and used for spaced repetition.
class Word {
  const Word(this.id, this.it, this.en, {this.emoji});

  final String id;
  final String it;
  final String en;
  final String? emoji;
}

/// A full sentence. [extraIt] / [extraEn] are wrong words used as distractors
/// in word-bank exercises.
class Sentence {
  const Sentence(
    this.it,
    this.en, {
    this.extraIt = const [],
    this.extraEn = const [],
  });

  final String it;
  final String en;
  final List<String> extraIt;
  final List<String> extraEn;

  List<String> get itTokens => tokenize(it);
  List<String> get enTokens => tokenize(en);
}

/// Splits a sentence into words, dropping punctuation.
List<String> tokenize(String s) => s
    .replaceAll(RegExp(r'[¿?¡!.,;:]'), '')
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .toList();

/// Lowercases, trims, strips punctuation and accents so typed answers
/// are compared fairly. German umlauts count as their plain letter and
/// ß as ss, so a keyboard without them still works.
String normalize(String s) {
  const from = 'àèéìíòóùúäöü';
  const to = 'aeeiioouuaou';
  var out = s.toLowerCase().trim();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r"[¿?¡!.,;:]"), '')
      .replaceAll("'", ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class LessonDef {
  const LessonDef({
    required this.id,
    required this.title,
    required this.words,
    required this.sentences,
  });

  final String id;
  final String title;
  final List<Word> words;
  final List<Sentence> sentences;
}

class UnitDef {
  const UnitDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.colorValue,
    required this.guide,
    required this.lessons,
    this.level = 'A1',
  });

  final String id;
  final String title;
  final String subtitle;

  /// CEFR level: 'A1', 'A2', 'B1', 'B2', 'C1' or 'C2'.
  final String level;

  /// ARGB colour, e.g. 0xFF58CC02.
  final int colorValue;

  /// Short grammar and culture tips shown in the unit guide.
  final List<String> guide;
  final List<LessonDef> lessons;
}

/// Short dialogue for the Stories feature.
class StoryLine {
  const StoryLine(this.speaker, this.it, this.en);

  final String speaker;
  final String it;
  final String en;
}

class StoryQuestion {
  const StoryQuestion(this.question, this.options, this.answerIndex);

  final String question;
  final List<String> options;
  final int answerIndex;
}

class StoryDef {
  const StoryDef({
    required this.id,
    required this.title,
    required this.emoji,
    required this.lines,
    required this.questions,
  });

  final String id;
  final String title;
  final String emoji;
  final List<StoryLine> lines;
  final List<StoryQuestion> questions;
}

class AlphabetEntry {
  const AlphabetEntry(this.symbol, this.sound, this.example, this.exampleEn);

  final String symbol;
  final String sound;
  final String example;
  final String exampleEn;
}

enum ExerciseType {
  /// Build the English sentence from tiles. Prompt is Italian.
  translateToEn,

  /// Build the Italian sentence from tiles. Prompt is English.
  translateToIt,

  /// Pick the right meaning from 4 options.
  multipleChoice,

  /// Match 5 Italian words with their English meaning.
  matchPairs,

  /// Hear Italian, type what you hear.
  listenType,

  /// Hear Italian, pick the matching English.
  listenSelect,

  /// Fill the blank in an Italian sentence.
  fillGap,

  /// Pick the word for an emoji picture.
  pictureSelect,

  /// Say the phrase aloud and rate yourself (no microphone permission needed).
  speak,

  /// Not a question. Shows a new word with its meaning and sound, so the
  /// learner meets it before being tested. [Exercise.prompt] is the Italian
  /// word, [Exercise.answer] the English meaning, [Exercise.hint] the emoji.
  teach,
}

class Exercise {
  const Exercise({
    required this.type,
    required this.prompt,
    required this.answer,
    this.options = const [],
    this.pairs = const [],
    this.audioText,
    this.wordIds = const [],
    this.hint,
  });

  final ExerciseType type;

  /// The question text shown to the learner.
  final String prompt;

  /// The single correct answer (the joined sentence for tile exercises).
  final String answer;

  /// Choices or tiles, already shuffled.
  final List<String> options;

  /// For matchPairs: list of [italian, english].
  final List<List<String>> pairs;

  /// Text read aloud by text-to-speech, if any.
  final String? audioText;

  /// Words this exercise trains, for spaced repetition.
  final List<String> wordIds;
  final String? hint;

  /// True for a "new word" card: shown, never graded.
  bool get isTeach => type == ExerciseType.teach;

  bool check(String given) => normalize(given) == normalize(answer);
}
