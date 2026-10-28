import 'dart:convert';

/// Backup file format. Pure Dart so it can be tested without a device.
///
/// Layout (schema 3):
/// ```
/// { "app": "multilingo", "schema": 3, "id": "...", "createdAt": "ISO-8601",
///   "label": "...", "kind": "manual|auto", "appVersion": "1.0.0",
///   "checksum": "fnv1a32 hex of activeCourse + profile + courses",
///   "activeCourse": "it",
///   "profile": { ...data shared by every language... },
///   "courses": { "it": { ...data of that language only... } } }
/// ```
/// `profile` holds what belongs to the learner (name, settings, gems, hearts,
/// streak, XP, quests, league). `courses` is keyed by course id and holds only
/// what belongs to one language (lessons, words, levels), so a future app that
/// teaches more languages keeps each language apart and shares the rest.
///
/// Every field of AppState must be listed in exactly one of
/// [profileStateKeys] or [courseStateKeys]. A test fails when a new field is
/// added to AppState without being listed, so nothing is ever left out of a
/// backup.

const backupApp = 'multilingo';

/// The app used to be called Parlo. Old backup files still carry that name.
const _legacyBackupApp = 'parlo';
const backupSchema = 3;

/// The course this build of the app teaches.
const defaultCourseId = 'it';

/// Shared by every language.
const profileStateKeys = {
  'onboarded',
  'name',
  'dailyGoalXp',
  'soundOn',
  'hapticsOn',
  'speechOn',
  'themeMode',
  'reminderOn',
  'reminderMinutes',
  'xp',
  'xpByDay',
  'streak',
  'longestStreak',
  'lastActiveDay',
  'freezes',
  'gems',
  'hearts',
  'heartsStamp',
  'xpBoostUntil',
  'questDay',
  'questProgress',
  'questClaimed',
  'achievements',
  'achievementsClaimed',
  'leagueTier',
  'leagueWeek',
  'lastLeagueResult',
};

/// Belongs to one language only.
const courseStateKeys = {
  'level',
  'completedLessons',
  'lessonRuns',
  'perfectLessons',
  'storiesDone',
  'passedLevels',
  'checkpointBest',
  'wordBox',
  'wordDue',
  'mistakes',
  'wordsCorrect',
};

/// Splits one AppState JSON map into (profile, course). A key that is in
/// neither list goes to the profile, so it is still saved.
(Map<String, dynamic>, Map<String, dynamic>) splitState(Map<String, dynamic> state) {
  final profile = <String, dynamic>{};
  final course = <String, dynamic>{};
  for (final e in state.entries) {
    (courseStateKeys.contains(e.key) ? course : profile)[e.key] = e.value;
  }
  return (profile, course);
}

/// The reverse of [splitState]. The profile wins when both have a key.
Map<String, dynamic> mergeState(
  Map<String, dynamic> profile,
  Map<String, dynamic> course,
) =>
    {...course, ...profile};

/// The one and only file name. Every export reuses it, so saving to the same
/// place replaces the old file instead of piling up copies.
const backupFileName = 'duolingo-backup.json';

const maxLabelLength = 40;

enum BackupKind { manual, auto }

enum BackupError {
  /// Not JSON at all.
  unreadable,

  /// JSON, but not a Multilingo backup.
  notMultilingo,

  /// Saved by a newer app version than this one understands.
  tooNew,

  /// Content was changed or cut off after saving.
  damaged,

  /// Valid file, but it holds no progress for the course we are running.
  noCourse,
}

class BackupException implements Exception {
  const BackupException(this.error);

  final BackupError error;

  @override
  String toString() => 'BackupException(${error.name})';
}

class BackupEnvelope {
  const BackupEnvelope({
    required this.id,
    required this.createdAt,
    required this.label,
    required this.kind,
    required this.appVersion,
    required this.courses,
    this.profile = const {},
    this.activeCourse = defaultCourseId,
  });

  /// Builds an envelope from whole app states (profile and course mixed), one
  /// per course. The shared profile comes from the [activeCourse] state.
  factory BackupEnvelope.fromStates({
    required String id,
    required DateTime createdAt,
    required String label,
    required BackupKind kind,
    required String appVersion,
    required Map<String, Map<String, dynamic>> states,
    String activeCourse = defaultCourseId,
  }) {
    final (profile, _) = splitState(states[activeCourse] ?? states.values.first);
    return BackupEnvelope(
      id: id,
      createdAt: createdAt,
      label: label,
      kind: kind,
      appVersion: appVersion,
      activeCourse: activeCourse,
      profile: profile,
      courses: {
        for (final e in states.entries) e.key: splitState(e.value).$2,
      },
    );
  }

  final String id;
  final DateTime createdAt;
  final String label;
  final BackupKind kind;
  final String appVersion;

  /// Course id to the data of that language only.
  final Map<String, Map<String, dynamic>> courses;

  /// Data shared by every language.
  final Map<String, dynamic> profile;

  /// The language the learner was on when this was saved.
  final String activeCourse;

  /// The full app state for [courseId]: shared profile plus that language.
  Map<String, dynamic> stateFor(String courseId) =>
      mergeState(profile, courses[courseId] ?? const {});

  BackupEnvelope copyWith({String? label, BackupKind? kind}) => BackupEnvelope(
        id: id,
        createdAt: createdAt,
        label: label ?? this.label,
        kind: kind ?? this.kind,
        appVersion: appVersion,
        courses: courses,
        profile: profile,
        activeCourse: activeCourse,
      );

  Map<String, dynamic> toJson() => {
        'app': backupApp,
        'schema': backupSchema,
        'id': id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'label': label,
        'kind': kind.name,
        'appVersion': appVersion,
        'checksum': checksumV3(activeCourse, profile, courses),
        'activeCourse': activeCourse,
        'profile': profile,
        'courses': courses,
      };

  String encode() => const JsonEncoder.withIndent(' ').convert(toJson());

  /// Reads and validates a backup. Accepts schema 1 (the bare state map the
  /// app used before backups existed) and upgrades it.
  static BackupEnvelope decode(String raw) {
    final Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      throw const BackupException(BackupError.unreadable);
    }
    if (parsed is! Map<String, dynamic>) {
      throw const BackupException(BackupError.unreadable);
    }
    return _migrate(parsed);
  }

  static BackupEnvelope _migrate(Map<String, dynamic> json) {
    // Schema 1: no envelope, just the state map.
    if (!json.containsKey('app')) {
      final looksLikeState =
          json.containsKey('completedLessons') && json.containsKey('xp');
      if (!looksLikeState) throw const BackupException(BackupError.notMultilingo);
      return BackupEnvelope.fromStates(
        id: 'legacy',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        label: 'Imported',
        kind: BackupKind.manual,
        appVersion: 'unknown',
        states: {defaultCourseId: json},
      );
    }
    if (json['app'] != backupApp && json['app'] != _legacyBackupApp) {
      throw const BackupException(BackupError.notMultilingo);
    }
    final schema = json['schema'];
    if (schema is! int || schema < 1) {
      throw const BackupException(BackupError.damaged);
    }
    if (schema > backupSchema) {
      throw const BackupException(BackupError.tooNew);
    }
    // Future migrations go here, one `if (schema < N)` block per step.
    final courses = json['courses'];
    if (courses is! Map || courses.isEmpty) {
      throw const BackupException(BackupError.damaged);
    }
    final typed = <String, Map<String, dynamic>>{};
    for (final e in courses.entries) {
      final v = e.value;
      if (e.key is! String || v is! Map<String, dynamic>) {
        throw const BackupException(BackupError.damaged);
      }
      typed[e.key as String] = v;
    }
    var profile = <String, dynamic>{};
    var active = defaultCourseId;
    if (schema < 3) {
      if (json['checksum'] != checksumOf(typed)) {
        throw const BackupException(BackupError.damaged);
      }
      // Schema 2 kept the whole state inside each course. Move the shared
      // part of the main course into the profile. Other courses stay whole,
      // so nothing in them is lost.
      active = typed.containsKey(defaultCourseId) ? defaultCourseId : typed.keys.first;
      final (p, c) = splitState(typed[active]!);
      profile = p;
      typed[active] = c;
    } else {
      final a = json['activeCourse'];
      final p = json['profile'];
      if (a is! String || !typed.containsKey(a) || p is! Map<String, dynamic>) {
        throw const BackupException(BackupError.damaged);
      }
      if (json['checksum'] != checksumV3(a, p, typed)) {
        throw const BackupException(BackupError.damaged);
      }
      active = a;
      profile = p;
    }
    final created = DateTime.tryParse('${json['createdAt']}');
    if (created == null) throw const BackupException(BackupError.damaged);
    return BackupEnvelope(
      id: '${json['id']}',
      createdAt: created,
      label: cleanLabel('${json['label'] ?? ''}'),
      kind: json['kind'] == 'auto' ? BackupKind.auto : BackupKind.manual,
      appVersion: '${json['appVersion'] ?? 'unknown'}',
      courses: typed,
      profile: profile,
      activeCourse: active,
    );
  }
}

/// Trims and caps a user-typed label.
String cleanLabel(String raw) {
  final t = raw.trim();
  return t.length > maxLabelLength ? t.substring(0, maxLabelLength) : t;
}

/// Checksum used by schema 1 and 2 files: the courses block only.
String checksumOf(Map<String, Map<String, dynamic>> courses) =>
    _fnv1a(jsonEncode(courses));

/// Checksum used by schema 3 files: active course, profile and courses.
String checksumV3(
  String activeCourse,
  Map<String, dynamic> profile,
  Map<String, Map<String, dynamic>> courses,
) =>
    _fnv1a(jsonEncode({'activeCourse': activeCourse, 'profile': profile, 'courses': courses}));

/// FNV-1a 32-bit. This detects truncation and accidental edits. It is not a
/// security feature.
String _fnv1a(String text) {
  var h = 0x811C9DC5;
  for (final b in utf8.encode(text)) {
    h ^= b;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}
