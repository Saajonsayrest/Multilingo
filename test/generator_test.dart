import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/data/languages.dart';
import 'package:multilingo/domain/exercise_generator.dart';
import 'package:multilingo/domain/models.dart';

void main() {
  for (final lang in languages) {
    group(lang.name, () => generatorTests(Course.of(lang.id)));
  }

  test('normalize treats German umlauts and ß like plain letters', () {
    expect(normalize('Schön'), normalize('schon'));
    expect(normalize('Straße'), 'strasse');
    expect(normalize('Über'), 'uber');
  });
}

void generatorTests(Course course) {
  final gen = ExerciseGenerator(allWords: course.allWords, random: Random(1));

  test('normalize ignores case, accents and punctuation', () {
    expect(normalize('  Perché, è così! '), 'perche e cosi');
    expect(normalize("L'acqua."), 'l acqua');
  });

  test('every lesson generates solvable exercises', () {
    for (final lesson in course.flatLessons) {
      final list = gen.forLesson(lesson);
      expect(list.length, greaterThanOrEqualTo(12), reason: lesson.id);
      for (final e in list) {
        switch (e.type) {
          case ExerciseType.multipleChoice ||
                ExerciseType.pictureSelect ||
                ExerciseType.listenSelect ||
                ExerciseType.fillGap:
            expect(e.options.where((o) => normalize(o) == normalize(e.answer)).length, 1,
                reason: '${lesson.id} ${e.prompt}: ${e.options} vs ${e.answer}');
            expect(e.options.map(normalize).toSet().length, e.options.length,
                reason: '${lesson.id} duplicate options ${e.options}');
          case ExerciseType.translateToEn || ExerciseType.translateToIt:
            // The tiles must be able to rebuild the answer.
            final pool = List<String>.of(e.options);
            for (final t in e.answer.split(' ')) {
              expect(pool.remove(t), isTrue, reason: '${lesson.id} missing "$t"');
            }
          case ExerciseType.matchPairs:
            expect(e.pairs.length, 5);
          case ExerciseType.listenType || ExerciseType.speak:
            expect(e.audioText, isNotNull);
          case ExerciseType.teach:
            expect(e.audioText, e.prompt, reason: lesson.id);
            expect(e.options, isEmpty);
        }
        expect(e.check(e.answer), isTrue, reason: lesson.id);
      }
    }
  });

  test('every word is taught before it is asked, and each is taught once', () {
    for (final lesson in course.flatLessons) {
      final list = gen.forLesson(lesson);
      final taught = <String>{};
      for (final e in list) {
        if (e.isTeach) {
          expect(taught.add(e.wordIds.single), isTrue,
              reason: '${lesson.id} taught twice');
        } else {
          for (final id in e.wordIds) {
            expect(taught, contains(id),
                reason: '${lesson.id}: "${e.prompt}" asked before it was taught');
          }
        }
      }
      expect(taught, {for (final w in lesson.words) w.id}, reason: lesson.id);
      expect(list.first.isTeach, isTrue, reason: '${lesson.id} must open with teaching');
    }
  });

  test('word practice produces mixed exercises', () {
    final words = course.flatLessons.first.words;
    final list = gen.forWords(words, count: 8);
    expect(list.length, greaterThanOrEqualTo(8));
    expect(gen.forWords(const []), isEmpty);
  });

  test('checkpoint covers the level, has no match or speak items, all solvable', () {
    for (final level in course.levels) {
      final lessons = course.lessonsOfLevel(level.id);
      final list = gen.forCheckpoint(lessons, count: 20);
      expect(list.length, 20, reason: level.id);
      expect(
        list.where((e) => e.type == ExerciseType.matchPairs || e.type == ExerciseType.speak),
        isEmpty,
      );
      for (final e in list) {
        expect(e.check(e.answer), isTrue);
        if (e.type == ExerciseType.translateToEn || e.type == ExerciseType.translateToIt) {
          final pool = List<String>.of(e.options);
          for (final t in e.answer.split(' ')) {
            expect(pool.remove(t), isTrue, reason: '${level.id} missing "$t"');
          }
        }
      }
      // Words come from many lessons, not just the first one.
      final wordIds = list.expand((e) => e.wordIds).toSet();
      expect(wordIds.length, greaterThan(5), reason: level.id);
    }
  });
}
