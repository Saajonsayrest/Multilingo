/// A language the app can teach. [id] is the course id used in saved data and
/// cloud saves. It never changes once shipped.
class Language {
  const Language(this.id, this.name, this.flag, this.ttsLocale);

  final String id;

  /// English name, used in texts like "Learn German".
  final String name;
  final String flag;

  /// Voice used for reading words out loud.
  final String ttsLocale;
}

const languages = [
  Language('it', 'Italian', '🇮🇹', 'it-IT'),
  Language('de', 'German', '🇩🇪', 'de-DE'),
];

/// The course every learner starts with. Old saves belong to it.
const defaultLanguageId = 'it';

Language languageById(String id) =>
    languages.firstWhere((l) => l.id == id, orElse: () => languages.first);

bool isKnownLanguage(String id) => languages.any((l) => l.id == id);
