import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/data/languages.dart';
import 'package:multilingo/domain/models.dart';

void main() {
  // Every language must pass the same checks.
  for (final lang in languages) {
    group(lang.name, () => courseTests(Course.of(lang.id)));
  }

  test('word and lesson ids never clash between languages', () {
    final seen = <String>{};
    for (final lang in languages) {
      final c = Course.of(lang.id);
      for (final id in [
        ...c.units.map((u) => u.id),
        ...c.flatLessons.map((l) => l.id),
        ...c.allWords.map((w) => w.id),
      ]) {
        expect(seen.add(id), isTrue, reason: '$id used twice');
      }
    }
  });

  test('German is a full course with its own sounds, stories and tips', () {
    final de = Course.of('de');
    expect(de.language.ttsLocale, 'de-DE');
    expect(de.alphabet.any((e) => e.symbol.contains('ß')), isTrue);
    expect(de.alphabet.any((e) => e.symbol.toLowerCase().contains('sch')), isTrue);
    for (final u in de.units) {
      expect(u.guide.length, 3, reason: u.id);
    }
  });

  test('tap-a-word hints work in German', () {
    final de = Course.of('de');
    final w = de.allWords.first;
    final pieces = de.hintPieces('${w.it}, xyzxyz');
    expect(pieces.first.word?.id, w.id);
    expect(pieces.last.word, isNull);
  });
}

void courseTests(Course course) {
  test('course runs A1 to C2 with the planned size', () {
    expect(course.levels.map((l) => l.id), ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
    expect(course.units.length, 55);
    expect(course.flatLessons.length, 220);
    expect(course.unitsOfLevel('A1').length, 9);
    expect(course.unitsOfLevel('A2').length, 10);
    expect(course.unitsOfLevel('B1').length, 10);
    expect(course.unitsOfLevel('B2').length, 10);
    expect(course.unitsOfLevel('C1').length, 8);
    expect(course.unitsOfLevel('C2').length, 8);
  });

  test('levels are in order and never interleave', () {
    final order = course.levels.map((l) => l.id).toList();
    var last = -1;
    for (final u in course.units) {
      final i = order.indexOf(u.level);
      expect(i, greaterThanOrEqualTo(last), reason: u.id);
      last = i;
    }
  });

  test('ids are unique', () {
    final lessons = course.flatLessons.map((l) => l.id).toList();
    expect(lessons.toSet().length, lessons.length);
    final words = course.allWords.map((w) => w.id).toList();
    expect(words.toSet().length, words.length);
  });

  test('every lesson has enough material for all exercise types', () {
    for (final l in course.flatLessons) {
      expect(l.words.length, greaterThanOrEqualTo(5), reason: l.id);
      expect(l.sentences.length, greaterThanOrEqualTo(4), reason: l.id);
      for (final s in l.sentences) {
        expect(s.itTokens.length, greaterThanOrEqualTo(2), reason: '${l.id} ${s.it}');
        expect(s.enTokens, isNotEmpty, reason: '${l.id} ${s.en}');
        expect(s.extraIt, isNotEmpty, reason: '${l.id} ${s.it}');
        expect(s.extraEn, isNotEmpty, reason: '${l.id} ${s.en}');
      }
    }
  });

  test('distractors never equal the right tokens', () {
    for (final l in course.flatLessons) {
      for (final s in l.sentences) {
        final it = s.itTokens.map(normalize).toSet();
        for (final x in s.extraIt) {
          expect(it.contains(normalize(x)), isFalse, reason: '${l.id}: $x in ${s.it}');
        }
        final en = s.enTokens.map(normalize).toSet();
        for (final x in s.extraEn) {
          expect(en.contains(normalize(x)), isFalse, reason: '${l.id}: $x in ${s.en}');
        }
      }
    }
  });

  test('stories and alphabet are well formed', () {
    expect(course.stories.length, greaterThanOrEqualTo(6));
    for (final st in course.stories) {
      expect(st.lines.length, greaterThanOrEqualTo(4));
      for (final q in st.questions) {
        expect(q.answerIndex, inInclusiveRange(0, q.options.length - 1));
      }
    }
    expect(course.alphabet.length, greaterThanOrEqualTo(25));
  });

  test('unlock order is sequential', () {
    final first = course.flatLessons.first.id;
    final second = course.flatLessons[1].id;
    expect(course.isUnlocked(first, {}, {}), isTrue);
    expect(course.isUnlocked(second, {}, {}), isFalse);
    expect(course.isUnlocked(second, {first}, {}), isTrue);
  });

  test('the next level stays locked until the checkpoint is passed', () {
    final a1 = course.lessonsOfLevel('A1').map((l) => l.id).toSet();
    final firstA2 = course.lessonsOfLevel('A2').first.id;
    expect(course.checkpointReady('A1', {}), isFalse);
    expect(course.checkpointReady('A1', a1), isTrue);
    expect(course.isUnlocked(firstA2, a1, {}), isFalse);
    expect(course.isUnlocked(firstA2, a1, {'A1'}), isTrue);
    expect(course.currentLevel(a1, {}), 'A1');
    expect(course.currentLevel(a1, {'A1'}), 'A2');
  });

  test('tap-a-word hints find words and short phrases', () {
    if (course.language.id != 'it') return;
    final pieces = course.hintPieces('Ciao, come stai?');
    expect(pieces.map((p) => p.text), ['Ciao,', 'come stai?']);
    expect(pieces[0].word?.en, 'hi');
    expect(pieces[1].word?.en, 'how are you');
    final unknown = course.hintPieces('zzzz ciao');
    expect(unknown.first.word, isNull);
    expect(unknown.last.word?.it, 'ciao');
  });
}
