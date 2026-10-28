import '../../domain/models.dart';

const List<AlphabetEntry> alphabet = [
  // The 21 letters of the Italian alphabet.
  AlphabetEntry('A', 'ah as in father', 'amico', 'friend'),
  AlphabetEntry('B', 'b as in book', 'bene', 'well, good'),
  AlphabetEntry('C', 'k as in cat (before a, o, u)', 'casa', 'house'),
  AlphabetEntry('D', 'd as in dog', 'dottore', 'doctor'),
  AlphabetEntry('E', 'eh as in bed, or short ay as in they', 'elefante', 'elephant'),
  AlphabetEntry('F', 'f as in fish', 'fiore', 'flower'),
  AlphabetEntry('G', 'g as in go (before a, o, u)', 'gatto', 'cat'),
  AlphabetEntry('H', 'always silent', 'hotel', 'hotel'),
  AlphabetEntry('I', 'ee as in see', 'isola', 'island'),
  AlphabetEntry('L', 'l as in light', 'latte', 'milk'),
  AlphabetEntry('M', 'm as in map', 'mare', 'sea'),
  AlphabetEntry('N', 'n as in net', 'naso', 'nose'),
  AlphabetEntry('O', 'aw as in saw, or short oh as in go', 'orso', 'bear'),
  AlphabetEntry('P', 'p as in spin, with no puff of air', 'pane', 'bread'),
  AlphabetEntry('Q', 'kw as in quick (always followed by u)', 'quadro', 'picture'),
  AlphabetEntry('R', 'rolled r, tap the tongue once or twice', 'rosa', 'rose'),
  AlphabetEntry('S', 's as in sun, or z between two vowels', 'sole', 'sun'),
  AlphabetEntry('T', 't as in top, with no puff of air', 'tavolo', 'table'),
  AlphabetEntry('U', 'oo as in food', 'uva', 'grape'),
  AlphabetEntry('V', 'v as in van', 'vino', 'wine'),
  AlphabetEntry('Z', 'ts as in cats, or dz as in suds', 'zero', 'zero'),

  // Special spellings and sounds.
  AlphabetEntry('CE / CI', 'ch as in church (before e, i)', 'cena', 'dinner'),
  AlphabetEntry('CH', 'k as in kite (only before e, i)', 'chi', 'who'),
  AlphabetEntry('GE / GI', 'j as in jump (before e, i)', 'gelato', 'ice cream'),
  AlphabetEntry('GH', 'hard g as in go (only before e, i)', 'funghi', 'mushrooms'),
  AlphabetEntry('GLI', 'ly as in million', 'famiglia', 'family'),
  AlphabetEntry('GN', 'ny as in canyon', 'bagno', 'bathroom'),
  AlphabetEntry('SC + E / I', 'sh as in shoe', 'pesce', 'fish'),
  AlphabetEntry('SCH', 'sk as in skip (before e, i)', 'pesche', 'peaches'),
  AlphabetEntry('ZZ', 'ts held longer, like "pits-sa"', 'pizza', 'pizza'),
  AlphabetEntry(
    'PP',
    'hold the p longer: pal-la, not pa-la',
    'palla',
    'ball (pala means shovel)',
  ),

  // Stressed vowels with accents. The accent marks where the stress falls.
  AlphabetEntry('à', 'ah, stressed, at the end of a word', 'città', 'city'),
  AlphabetEntry('è', 'eh, open and stressed (like bed)', 'caffè', 'coffee'),
  AlphabetEntry('é', 'ay, closed and stressed, short', 'perché', 'why, because'),
  AlphabetEntry('ì', 'ee, stressed', 'così', 'so, like this'),
  AlphabetEntry('ò', 'aw, open and stressed (like dog)', 'però', 'but'),
  AlphabetEntry('ù', 'oo, stressed', 'può', 'he or she can'),
];
