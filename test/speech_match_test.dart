import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/speech_match.dart';

void main() {
  test('exact phrase scores 1, ignoring case, accents and punctuation', () {
    expect(speechMatch('buongiorno come stai', 'Buongiorno, come stai?'), 1);
    expect(speechMatch('Es ist schön', 'Es ist schon!'), 1);
  });

  test('wrong or empty speech fails', () {
    expect(speechMatch('', 'ciao come stai'), 0);
    expect(speechMatch('completely different words', 'ciao come stai'), 0);
    expect(speechPasses('ciao', 'ciao come stai bene oggi'), isFalse);
  });

  test('a little noise is forgiven', () {
    // One missing short word out of five is still a pass.
    expect(speechPasses('ich möchte einen Kaffee', 'Ich möchte einen Kaffee bitte'), isTrue);
    // One wrong letter in a long word.
    expect(speechPasses('ich habe gestern gearbeitet', 'Ich habe gestern gearbeitat'), isTrue);
    // But a wrong letter in a short word is a different word.
    expect(speechMatch('das ist ein hund', 'das ist ein bund'), lessThan(1));
  });

  test('word order inside the phrase is ignored', () {
    expect(speechMatch('stai come ciao', 'ciao come stai'), 1);
  });

  test('extra words cost a little', () {
    final clean = speechMatch('ciao come stai', 'ciao come stai');
    final noisy = speechMatch('ciao come stai uno due', 'ciao come stai');
    expect(noisy, lessThan(clean));
    expect(noisy, greaterThan(0.7));
  });
}
