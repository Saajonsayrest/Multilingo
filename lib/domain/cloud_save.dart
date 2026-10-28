import 'dart:convert';

import 'state_split.dart';

/// Version of the cloud document layout. A newer app may write a higher
/// number. This app then refuses to read it instead of guessing.
const cloudSchema = 1;

/// Restore points live in fixed slots c0 to c4. A sixth one replaces the
/// oldest, so one account can never grow past six documents.
const checkpointSlots = 5;

/// Firestore stops at 1 MiB per document. Stay well below it.
const maxCloudBytes = 900 * 1024;

const maxLabelLength = 40;

enum CloudError {
  /// Saved by a newer app version than this one understands.
  tooNew,

  /// The stored data is incomplete or has the wrong shape.
  damaged,

  /// Valid data, but it holds no progress for any course this app teaches.
  noCourse,

  /// The save would not fit in one Firestore document.
  tooBig,
}

class CloudException implements Exception {
  const CloudException(this.error);

  final CloudError error;

  @override
  String toString() => 'CloudException(${error.name})';
}

/// One account's progress as stored in the cloud (or about to be).
///
/// Layout of `users/{uid}`:
/// ```
/// { schema, rev, savedAt (ms since epoch), appVersion, activeCourse,
///   profile: { ...data shared by every language... },
///   courses: { "it": { ...data of that language only... } } }
/// ```
class CloudSave {
  const CloudSave({
    required this.savedAt,
    required this.appVersion,
    required this.activeCourse,
    required this.profile,
    required this.courses,
    this.rev = 0,
  });

  /// Counts the writes to the cloud save, starting at 1. 0 means not stored
  /// yet. The rules only accept a write that is exactly one higher than the
  /// stored value, so two phones can never overwrite each other unseen.
  final int rev;
  final DateTime savedAt;
  final String appVersion;

  /// The language the learner was on when this was saved.
  final String activeCourse;

  /// Data shared by every language.
  final Map<String, dynamic> profile;

  /// Course id to the data of that language only.
  final Map<String, Map<String, dynamic>> courses;

  /// The full app state for [courseId]: shared profile plus that language.
  Map<String, dynamic> stateFor(String courseId) =>
      mergeState(profile, courses[courseId] ?? const {});

  CloudSave withRev(int value) => CloudSave(
        rev: value,
        savedAt: savedAt,
        appVersion: appVersion,
        activeCourse: activeCourse,
        profile: profile,
        courses: courses,
      );

  Map<String, dynamic> toMap() => {
        'schema': cloudSchema,
        'rev': rev,
        'savedAt': savedAt.toUtc().millisecondsSinceEpoch,
        'appVersion': appVersion,
        'activeCourse': activeCourse,
        'profile': profile,
        'courses': courses,
      };

  /// Short code of the progress itself. It ignores [rev] and [savedAt] and the
  /// order of keys, so equal progress gives an equal code on any phone. It
  /// detects changes. It is not a security feature.
  String get fingerprint => _fnv1a(jsonEncode(_sorted({
        'activeCourse': activeCourse,
        'profile': profile,
        'courses': courses,
      })));

  /// Throws [CloudError.tooBig] when this save would not fit in a document.
  void checkSize() {
    if (utf8.encode(jsonEncode(toMap())).length > maxCloudBytes) {
      throw const CloudException(CloudError.tooBig);
    }
  }

  /// Reads and checks a document. Rejects a newer schema and anything that
  /// does not have the expected shape.
  static CloudSave fromMap(Map<String, dynamic> map, {bool withRev = true}) {
    final schema = map['schema'];
    if (schema is! int || schema < 1) throw const CloudException(CloudError.damaged);
    if (schema > cloudSchema) throw const CloudException(CloudError.tooNew);
    final rev = map['rev'];
    final savedAt = map['savedAt'];
    final app = map['appVersion'];
    final active = map['activeCourse'];
    final profile = map['profile'];
    final courses = map['courses'];
    if ((withRev && (rev is! int || rev < 1)) ||
        savedAt is! int ||
        app is! String ||
        active is! String ||
        profile is! Map ||
        courses is! Map ||
        courses.isEmpty) {
      throw const CloudException(CloudError.damaged);
    }
    final typed = <String, Map<String, dynamic>>{};
    for (final e in courses.entries) {
      final v = e.value;
      if (e.key is! String || v is! Map) throw const CloudException(CloudError.damaged);
      typed[e.key as String] = Map<String, dynamic>.from(v);
    }
    if (!typed.containsKey(active)) throw const CloudException(CloudError.damaged);
    return CloudSave(
      rev: rev is int ? rev : 0,
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt, isUtc: true),
      appVersion: app,
      activeCourse: active,
      profile: Map<String, dynamic>.from(profile),
      courses: typed,
    );
  }
}

enum CheckpointReason {
  /// A level, a badge, a streak record or every 5th lesson.
  milestone,

  /// The first save of a new day.
  daily,

  /// Progress that a restore or a choice between two copies replaced.
  replaced,

  /// Progress that a reset erased.
  reset,
}

/// A restore point stored in the cloud.
class CloudCheckpoint {
  const CloudCheckpoint({
    required this.slot,
    required this.reason,
    required this.label,
    required this.save,
  });

  /// 0 to [checkpointSlots] - 1.
  final int slot;
  final CheckpointReason reason;
  final String label;
  final CloudSave save;

  DateTime get createdAt => save.savedAt;

  String get docId => 'c$slot';

  Map<String, dynamic> toMap() => {
        ...save.toMap()..remove('rev'),
        'reason': reason.name,
        'label': cleanLabel(label),
      };

  static CloudCheckpoint fromDoc(String id, Map<String, dynamic> map) {
    final match = RegExp(r'^c([0-4])$').firstMatch(id);
    if (match == null) throw const CloudException(CloudError.damaged);
    final reason = CheckpointReason.values.asNameMap()['${map['reason']}'];
    return CloudCheckpoint(
      slot: int.parse(match.group(1)!),
      reason: reason ?? CheckpointReason.daily,
      label: cleanLabel('${map['label'] ?? ''}'),
      save: CloudSave.fromMap(map, withRev: false),
    );
  }
}

/// The slot to write the next restore point to: the first free one, else the
/// one holding the oldest.
int nextCheckpointSlot(Iterable<CloudCheckpoint> existing) {
  final used = {for (final c in existing) c.slot: c};
  for (var i = 0; i < checkpointSlots; i++) {
    if (!used.containsKey(i)) return i;
  }
  final oldest = used.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return oldest.first.slot;
}

enum SyncAction {
  /// Both sides already agree.
  nothing,

  /// The phone is newer: send it.
  upload,

  /// The cloud is newer: take it.
  download,

  /// Both changed since they last agreed: the learner must choose.
  conflict,
}

/// Decides what a sync must do. Pure, so every case can be tested.
///
/// [cloudRev] is null when the account has no save yet. [baseRev] is the
/// cloud revision this phone last agreed with, null when it never did (or did
/// so for another account). [localDirty] means the phone changed since then.
/// [localHasProgress] means the phone holds a started course, not an empty
/// first launch. [sameContent] means the cloud and the phone hold the same
/// progress, whatever their revision numbers say.
SyncAction decideSync({
  required int? cloudRev,
  required int? baseRev,
  required bool localDirty,
  required bool localHasProgress,
  bool sameContent = false,
}) {
  if (cloudRev == null) {
    return localHasProgress ? SyncAction.upload : SyncAction.nothing;
  }
  if (sameContent) return SyncAction.nothing;
  if (baseRev == null) {
    return localHasProgress ? SyncAction.conflict : SyncAction.download;
  }
  if (cloudRev == baseRev) {
    return localDirty ? SyncAction.upload : SyncAction.nothing;
  }
  return localDirty ? SyncAction.conflict : SyncAction.download;
}

/// Trims and caps a label.
String cleanLabel(String raw) {
  final t = raw.trim();
  return t.length > maxLabelLength ? t.substring(0, maxLabelLength) : t;
}

/// Copies [value] with every map's keys in sorted order, so two equal
/// structures encode to the same text.
Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => '$k').toList()..sort();
    return {for (final k in keys) k: _sorted(value[k])};
  }
  if (value is List) return [for (final e in value) _sorted(e)];
  return value;
}

/// FNV-1a 32-bit.
String _fnv1a(String text) {
  var h = 0x811C9DC5;
  for (final b in utf8.encode(text)) {
    h ^= b;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}
