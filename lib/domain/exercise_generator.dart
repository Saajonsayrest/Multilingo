import 'dart:math';

import 'models.dart';

/// Builds exercises from course content. Pure Dart, seedable for tests.
class ExerciseGenerator {
  ExerciseGenerator({required this.allWords, Random? random})
      : _rnd = random ?? Random();

  /// Every word in the course. Used for distractors.
  final List<Word> allWords;
  final Random _rnd;

  /// A full lesson: teach, then test. [teachSize] new words are shown as
  /// "new word" cards, then asked right away, before the next group starts.
  /// After that come sentences. [weakWordIds] get extra practice at the end.
  List<Exercise> forLesson(
    LessonDef lesson, {
    Set<String> weakWordIds = const {},
    int teachSize = 2,
  }) {
    final words = List<Word>.of(lesson.words)..shuffle(_rnd);
    final out = <Exercise>[];

    // Phase 1: meet each word, then recognise it.
    for (var i = 0; i < words.length; i += teachSize) {
      final group = words.skip(i).take(teachSize).toList();
      for (final w in group) {
        out.add(_teach(w));
      }
      for (final w in group) {
        out.add(w.emoji != null ? _picture(w, lesson) : _choice(w, lesson));
      }
    }
    out.add(_match(words.take(5).toList()));
    for (final w in words.take(3)) {
      out.add(_choice(w, lesson, reverse: true));
    }
    out.add(_listenSelect(words.first, lesson));

    // Phase 2: sentences.
    final sentences = List<Sentence>.of(lesson.sentences)..shuffle(_rnd);
    for (var i = 0; i < sentences.length; i++) {
      final s = sentences[i];
      switch (i % 4) {
        case 0:
          out.add(_tiles(s, toItalian: false));
        case 1:
          out.add(_fillGap(s, lesson));
        case 2:
          out.add(_tiles(s, toItalian: true));
        default:
          out.add(_listenType(s));
      }
    }
    out.add(_speak(sentences.first));

    // Phase 3: extra drill on weak words.
    final weak = lesson.words.where((w) => weakWordIds.contains(w.id)).take(2);
    for (final w in weak) {
      out.add(_choice(w, lesson, reverse: true));
    }
    return out;
  }

  /// A level checkpoint: [count] questions sampled across every lesson of the
  /// level, half on words and half on sentences. No match or speak items, so
  /// every question has one clear right answer.
  List<Exercise> forCheckpoint(List<LessonDef> lessons, {int count = 20}) {
    if (lessons.isEmpty) return const [];
    final wordTarget = count ~/ 2;
    final out = <Exercise>[];

    // Words: one per lesson first (round robin), so all units are covered.
    final byLesson = [
      for (final l in lessons) (List<Word>.of(l.words)..shuffle(_rnd)),
    ];
    final order = List<int>.generate(lessons.length, (i) => i)..shuffle(_rnd);
    var round = 0;
    while (out.length < wordTarget) {
      final li = order[round % order.length];
      final pool = byLesson[li];
      final w = pool[(round ~/ order.length) % pool.length];
      switch (round % 3) {
        case 0:
          out.add(_choice(w, lessons[li]));
        case 1:
          out.add(_choice(w, lessons[li], reverse: true));
        default:
          out.add(_listenSelect(w, lessons[li]));
      }
      round++;
    }

    // Sentences.
    final pairs = <(LessonDef, Sentence)>[
      for (final l in lessons)
        for (final s in l.sentences) (l, s),
    ]..shuffle(_rnd);
    var i = 0;
    while (out.length < count && pairs.isNotEmpty) {
      final (lesson, s) = pairs[i % pairs.length];
      switch (i % 4) {
        case 0:
          out.add(_tiles(s, toItalian: false));
        case 1:
          out.add(_fillGap(s, lesson));
        case 2:
          out.add(_tiles(s, toItalian: true));
        default:
          out.add(_listenType(s));
      }
      i++;
    }
    return out;
  }

  /// Mixed practice over arbitrary words (spaced repetition, mistakes review).
  List<Exercise> forWords(List<Word> words, {int count = 10}) {
    if (words.isEmpty) return const [];
    final pool = List<Word>.of(words)..shuffle(_rnd);
    final out = <Exercise>[];
    var i = 0;
    while (out.length < count) {
      final w = pool[i % pool.length];
      switch (i % 4) {
        case 0:
          out.add(_choice(w, null));
        case 1:
          out.add(_choice(w, null, reverse: true));
        case 2:
          out.add(_listenSelect(w, null));
        default:
          out.add(_typeWord(w));
      }
      i++;
    }
    if (pool.length >= 5) out.insert(min(3, out.length), _match(pool.take(5).toList()));
    return out;
  }

  // ---- builders -----------------------------------------------------------

  List<Word> _distractors(Word target, LessonDef? lesson, int n) {
    final local = (lesson?.words ?? const <Word>[])
        .where((w) => w.id != target.id)
        .toList()
      ..shuffle(_rnd);
    final rest = allWords
        .where((w) => w.id != target.id && !local.contains(w))
        .toList()
      ..shuffle(_rnd);
    final seen = <String>{normalize(target.en), normalize(target.it)};
    final out = <Word>[];
    for (final w in [...local, ...rest]) {
      if (out.length == n) break;
      if (seen.add(normalize(w.en))) out.add(w);
    }
    return out;
  }

  Exercise _teach(Word w) => Exercise(
        type: ExerciseType.teach,
        prompt: w.it,
        answer: w.en,
        hint: w.emoji,
        audioText: w.it,
        wordIds: [w.id],
      );

  Exercise _choice(Word w, LessonDef? lesson, {bool reverse = false}) {
    final d = _distractors(w, lesson, 3);
    final correct = reverse ? w.it : w.en;
    final options = [correct, ...d.map((x) => reverse ? x.it : x.en)]
      ..shuffle(_rnd);
    return Exercise(
      type: ExerciseType.multipleChoice,
      prompt: reverse ? 'How do you say "${w.en}"?' : 'What does "${w.it}" mean?',
      answer: correct,
      options: options,
      audioText: reverse ? null : w.it,
      wordIds: [w.id],
    );
  }

  Exercise _picture(Word w, LessonDef lesson) {
    final d = _distractors(w, lesson, 3);
    final options = [w.it, ...d.map((x) => x.it)]..shuffle(_rnd);
    return Exercise(
      type: ExerciseType.pictureSelect,
      prompt: w.emoji!,
      answer: w.it,
      options: options,
      audioText: w.it,
      wordIds: [w.id],
      hint: 'Which one is "${w.en}"?',
    );
  }

  Exercise _match(List<Word> five) => Exercise(
        type: ExerciseType.matchPairs,
        prompt: 'Tap the matching pairs',
        answer: five.map((w) => w.it).join(' '),
        pairs: [for (final w in five) [w.it, w.en]],
        wordIds: [for (final w in five) w.id],
      );

  Exercise _listenSelect(Word w, LessonDef? lesson) {
    final d = _distractors(w, lesson, 3);
    final options = [w.en, ...d.map((x) => x.en)]..shuffle(_rnd);
    return Exercise(
      type: ExerciseType.listenSelect,
      prompt: 'Tap what you hear',
      answer: w.en,
      options: options,
      audioText: w.it,
      wordIds: [w.id],
    );
  }

  Exercise _typeWord(Word w) => Exercise(
        type: ExerciseType.listenType,
        prompt: 'Type what you hear',
        answer: w.it,
        audioText: w.it,
        wordIds: [w.id],
      );

  Exercise _tiles(Sentence s, {required bool toItalian}) {
    final answerTokens = toItalian ? s.itTokens : s.enTokens;
    final extras = toItalian ? s.extraIt : s.extraEn;
    final options = [...answerTokens, ...extras]..shuffle(_rnd);
    return Exercise(
      type: toItalian ? ExerciseType.translateToIt : ExerciseType.translateToEn,
      prompt: toItalian ? s.en : s.it,
      answer: answerTokens.join(' '),
      options: options,
      audioText: toItalian ? null : s.it,
    );
  }

  Exercise _fillGap(Sentence s, LessonDef lesson) {
    final tokens = s.itTokens;
    // Blank the longest word: it is usually the content word.
    var idx = 0;
    for (var i = 1; i < tokens.length; i++) {
      if (tokens[i].length > tokens[idx].length) idx = i;
    }
    final answer = tokens[idx];
    final shown = [...tokens]..[idx] = '_____';
    final pool = {
      ...s.extraIt,
      ...lesson.words.map((w) => w.it),
    }.where((w) => normalize(w) != normalize(answer) && !w.contains(' ')).toList()
      ..shuffle(_rnd);
    final options = [answer, ...pool.take(3)]..shuffle(_rnd);
    return Exercise(
      type: ExerciseType.fillGap,
      prompt: shown.join(' '),
      answer: answer,
      options: options,
      audioText: s.it,
      hint: s.en,
    );
  }

  Exercise _listenType(Sentence s) => Exercise(
        type: ExerciseType.listenType,
        prompt: 'Type what you hear',
        answer: s.itTokens.join(' '),
        audioText: s.it,
      );

  Exercise _speak(Sentence s) => Exercise(
        type: ExerciseType.speak,
        prompt: s.it,
        answer: s.it,
        audioText: s.it,
        hint: s.en,
      );
}
