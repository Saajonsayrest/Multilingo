import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/languages.dart';
import '../domain/backup.dart';
import '../domain/backup_milestone.dart';
import '../domain/dates.dart';
import 'app_state.dart';
import 'controller.dart';
import 'course_state.dart';

const appVersion = '0.1.0';

const _checkpointsKey = 'multilingo.checkpoints.v1';

const maxManualCheckpoints = 5;
const maxAutoCheckpoints = 2;
const autoSaveDelay = Duration(seconds: 4);
const autoCheckpointEvery = Duration(hours: 24);

/// Where the single rolling backup file lives. Tests override this.
final backupDirProvider = Provider<Future<Directory>>(
  (ref) => getApplicationDocumentsDirectory(),
);

final backupServiceProvider = Provider<BackupService>((ref) {
  final service = BackupService(ref);
  ref.onDispose(service.dispose);
  return service;
});

const _lastHintDayKey = 'multilingo.backupHintDay.v1';

/// Set when the learner reaches a milestone: the text to show ("10 lessons
/// done"). The lesson result screen shows a reminder to save a copy and then
/// clears it.
final backupHintProvider = NotifierProvider<BackupHint, String?>(BackupHint.new);

class BackupHint extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String label) => state = label;
  void clear() => state = null;
}

/// What a restore will change, shown to the learner before they confirm.
class BackupSummary {
  const BackupSummary({
    required this.label,
    required this.createdAt,
    required this.xp,
    required this.lessons,
    required this.streak,
    required this.courseIds,
  });

  final String label;
  final DateTime createdAt;
  final int xp;
  final int lessons;
  final int streak;
  final List<String> courseIds;
}

class BackupService {
  BackupService(this._ref);

  final Ref _ref;
  Timer? _debounce;
  bool _writing = false;
  bool _dirty = false;

  // ---- building envelopes ------------------------------------------------------

  String get _active => _ref.read(activeCourseProvider);

  /// Saved progress of every language except the one being learned now.
  Map<String, Map<String, dynamic>> _otherCourses() => {
        for (final e in readStash(_ref.read(prefsProvider)).entries)
          if (e.key != _active) e.key: e.value,
      };

  /// Snapshot of everything we know, including courses this version of the
  /// app cannot show yet (kept so a newer app can use them later).
  BackupEnvelope snapshot({
    required String label,
    BackupKind kind = BackupKind.manual,
  }) {
    final now = _ref.read(clockProvider)();
    final (profile, course) = splitState(_ref.read(appProvider).toJson());
    return BackupEnvelope(
      id: '${now.microsecondsSinceEpoch}',
      createdAt: now,
      label: cleanLabel(label).isEmpty ? defaultLabel(now) : cleanLabel(label),
      kind: kind,
      appVersion: appVersion,
      activeCourse: _active,
      profile: profile,
      courses: {
        ..._otherCourses(),
        _active: course,
      },
    );
  }

  static String defaultLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  BackupSummary summarize(BackupEnvelope e) {
    final shown = e.courses.containsKey(_active) ? _active : e.activeCourse;
    final s = AppState.fromJson(e.stateFor(shown));
    return BackupSummary(
      label: e.label,
      createdAt: e.createdAt,
      xp: s.xp,
      lessons: s.completedLessons.length,
      streak: s.streak,
      courseIds: e.courses.keys.toList(),
    );
  }

  // ---- the single rolling file ----------------------------------------------------

  Future<File> rollingFile() async {
    final dir = await _ref.read(backupDirProvider);
    return File('${dir.path}/$backupFileName');
  }

  /// Rewrites the one backup file. Writes to a temporary file first and then
  /// renames it, so a crash mid-write can never leave a half file behind.
  Future<File> writeRolling() async {
    final file = await rollingFile();
    final tmp = File('${file.path}.tmp');
    final text = snapshot(label: 'Latest').encode();
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(file.path);
    return file;
  }

  /// Call after every state change. Waits a few seconds so a burst of
  /// changes causes one write, never one per tap.
  void scheduleAutoSave() {
    if (!_ref.read(appProvider).onboarded) return;
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(autoSaveDelay, _flush);
  }

  /// Call with the old and new state after every change. At a milestone
  /// (a level passed, a new badge, a streak record, every 5th lesson) the
  /// backup file is rewritten at once instead of after the few seconds wait.
  /// The learner is also reminded, once a day at most, to save a copy outside
  /// the phone, because the file in the app is lost when the app is removed.
  Future<void> noteChange(AppState? before, AppState after) async {
    if (before == null || !after.onboarded) return;
    final label = milestoneFor(before, after);
    if (label == null) return;

    final prefs = _ref.read(prefsProvider);
    final today = dayKey(_ref.read(clockProvider)());
    if (prefs.getString(_lastHintDayKey) != today) {
      prefs.setString(_lastHintDayKey, today);
      _ref.read(backupHintProvider.notifier).show(label);
    }

    if (_writing) {
      // A write is already running: the normal path will write once more.
      scheduleAutoSave();
      return;
    }
    _debounce?.cancel();
    _dirty = false;
    _writing = true;
    try {
      await writeRolling();
    } catch (_) {
      _dirty = true;
    } finally {
      _writing = false;
    }
    if (_dirty) scheduleAutoSave();
  }

  Future<void> _flush() async {
    if (_writing) {
      // A write is running: remember to write again afterwards.
      _debounce = Timer(autoSaveDelay, _flush);
      return;
    }
    if (!_dirty) return;
    _writing = true;
    _dirty = false;
    try {
      await writeRolling();
      await _dailyCheckpoint();
    } catch (_) {
      // Disk full or similar: try again on the next change.
      _dirty = true;
    } finally {
      _writing = false;
    }
  }

  void dispose() => _debounce?.cancel();

  // ---- checkpoints ------------------------------------------------------------------

  List<BackupEnvelope> checkpoints() {
    final raw = _ref.read(prefsProvider).getStringList(_checkpointsKey) ?? [];
    final out = <BackupEnvelope>[];
    for (final text in raw) {
      try {
        out.add(BackupEnvelope.decode(text));
      } on BackupException {
        // Skip an unreadable entry instead of hiding all the others.
      }
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<void> _saveCheckpoints(List<BackupEnvelope> list) async {
    final manual = list.where((e) => e.kind == BackupKind.manual).take(maxManualCheckpoints);
    final auto = list.where((e) => e.kind == BackupKind.auto).take(maxAutoCheckpoints);
    final kept = [...manual, ...auto]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _ref
        .read(prefsProvider)
        .setStringList(_checkpointsKey, kept.map((e) => e.encode()).toList());
  }

  /// Adds a checkpoint. Oldest ones of the same kind are dropped past the cap.
  Future<BackupEnvelope> createCheckpoint(
    String label, {
    BackupKind kind = BackupKind.manual,
  }) async {
    final env = snapshot(label: label, kind: kind);
    await _saveCheckpoints([env, ...checkpoints()]);
    return env;
  }

  Future<void> deleteCheckpoint(String id) async {
    await _saveCheckpoints(checkpoints().where((e) => e.id != id).toList());
  }

  Future<void> renameCheckpoint(String id, String label) async {
    final clean = cleanLabel(label);
    if (clean.isEmpty) return;
    await _saveCheckpoints([
      for (final e in checkpoints()) e.id == id ? e.copyWith(label: clean) : e,
    ]);
  }

  Future<void> _dailyCheckpoint() async {
    final now = _ref.read(clockProvider)();
    final autos = checkpoints().where((e) => e.kind == BackupKind.auto);
    if (autos.isNotEmpty &&
        now.difference(autos.first.createdAt) < autoCheckpointEvery) {
      return;
    }
    await createCheckpoint('Automatic', kind: BackupKind.auto);
  }

  // ---- restore ---------------------------------------------------------------------------

  /// Replaces the current progress with [envelope]. The current progress is
  /// saved as an automatic checkpoint first, so a restore can be undone.
  Future<void> restore(BackupEnvelope envelope) async {
    // The language the file was saved in, if this app teaches it. Otherwise
    // Italian, the first course. A file with neither has nothing to show.
    final target = isKnownLanguage(envelope.activeCourse) &&
            envelope.courses.containsKey(envelope.activeCourse)
        ? envelope.activeCourse
        : (envelope.courses.containsKey(defaultCourseId) ? defaultCourseId : null);
    if (target == null) {
      throw const BackupException(BackupError.noCourse);
    }
    final AppState restored;
    try {
      restored = AppState.fromJson(envelope.stateFor(target)).sanitized();
    } catch (_) {
      throw const BackupException(BackupError.damaged);
    }
    // Remember the other courses, including ones this version cannot show.
    final others = {
      for (final e in envelope.courses.entries)
        if (e.key != target) e.key: e.value,
    };
    final prefs = _ref.read(prefsProvider);
    if (_ref.read(appProvider).onboarded) {
      await createCheckpoint('Before restore', kind: BackupKind.auto);
    }
    // A restore replaces everything, so other languages come from the file
    // too. The checkpoint above still holds the ones we had before.
    writeStash(prefs, others);
    _ref.read(activeCourseProvider.notifier).set(target);
    restored.onboarded = true;
    _ref.read(appProvider.notifier).restoreFrom(restored);
    scheduleAutoSave();
  }
}
