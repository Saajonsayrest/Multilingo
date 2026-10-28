import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/languages.dart';
import '../domain/cloud_save.dart';
import '../domain/dates.dart';
import '../domain/milestone.dart';
import '../domain/state_split.dart';
import 'app_state.dart';
import 'auth_gateway.dart';
import 'cloud_store.dart';
import 'controller.dart';
import 'course_state.dart';

const appVersion = '0.1.0';

const _metaKey = 'multilingo.cloud.v1';

/// A new daily restore point is made when the newest one is older than this.
const dailyCheckpointEvery = Duration(hours: 24);

/// Waits after the last change before sending. A burst of taps in a lesson
/// causes one write. Tests override this.
final cloudSaveDelayProvider = Provider<Duration>((ref) => const Duration(seconds: 6));

const _retryDelays = [
  Duration(seconds: 15),
  Duration(seconds: 30),
  Duration(minutes: 1),
  Duration(minutes: 2),
  Duration(minutes: 5),
];

enum SyncPhase {
  /// Firebase is not set up in this build. The app works on this phone only.
  unavailable,

  /// No account yet (before the first lesson, or after signing out).
  signedOut,

  /// Everything that was saved is in the cloud, or waits for the next change.
  idle,

  syncing,

  /// No connection. Progress is safe on the phone and is sent later.
  offline,

  /// The server refused, or the data could not be read.
  error,

  /// This phone and the cloud both changed. The learner must choose.
  conflict,
}

/// The two copies the learner must choose between.
class SyncConflict {
  const SyncConflict({required this.cloud, required this.local});

  final CloudSave cloud;
  final CloudSave local;
}

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.unavailable,
    this.user,
    this.lastSynced,
    this.pending = false,
    this.conflict,
    this.error,
  });

  final SyncPhase phase;
  final CloudUser? user;
  final DateTime? lastSynced;

  /// The phone holds changes the cloud does not have yet.
  final bool pending;
  final SyncConflict? conflict;

  /// What went wrong when [phase] is [SyncPhase.error].
  final Object? error;
}

/// The phone has changes the cloud does not hold, so it cannot forget them.
class UnsavedProgress implements Exception {
  const UnsavedProgress();

  @override
  String toString() => 'UnsavedProgress';
}

/// What a save contains, shown before the learner chooses it.
class SaveSummary {
  const SaveSummary({
    required this.savedAt,
    required this.xp,
    required this.lessons,
    required this.streak,
    required this.courseIds,
  });

  final DateTime savedAt;
  final int xp;
  final int lessons;
  final int streak;
  final List<String> courseIds;
}

SaveSummary summarize(CloudSave save, {String? preferredCourse}) {
  final shown = preferredCourse != null && save.courses.containsKey(preferredCourse)
      ? preferredCourse
      : save.activeCourse;
  var xp = 0, lessons = 0, streak = 0;
  try {
    final s = AppState.fromJson(save.stateFor(shown));
    xp = s.xp;
    lessons = s.completedLessons.length;
    streak = s.streak;
  } catch (_) {
    // A damaged save shows zeros instead of crashing the screen.
  }
  return SaveSummary(
    savedAt: save.savedAt,
    xp: xp,
    lessons: lessons,
    streak: streak,
    courseIds: save.courses.keys.toList(),
  );
}

final cloudSyncProvider = NotifierProvider<CloudSync, SyncStatus>(CloudSync.new);

const _hintDayKey = 'multilingo.accountHintDay.v1';

/// Set when the learner reaches a milestone without an email account: the
/// text to show ("10 lessons done"). The lesson result screen offers to create
/// an account, at most once a day, and then clears it.
final accountHintProvider = NotifierProvider<AccountHint, String?>(AccountHint.new);

class AccountHint extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String label) => state = label;
  void clear() => state = null;
}

/// Keeps the progress on this phone and the progress in the cloud in step.
///
/// The phone is always the working copy, so the app is fast and works with no
/// connection. The cloud is the safe copy. A sync reads the cloud, compares
/// it with the phone using [decideSync], and then uploads, downloads or asks
/// the learner. Nothing is replaced without keeping the other copy as a
/// restore point first.
class CloudSync extends Notifier<SyncStatus> {
  Timer? _timer;
  Timer? _retry;
  int _retryStep = 0;
  Future<void>? _run;
  bool _again = false;
  bool _signingIn = false;

  /// True while signing out or deleting, so nothing starts a new account or
  /// uploads the data that is being removed.
  bool _locked = false;

  String? _pendingMilestone;
  CloudUser? _user;
  DateTime? _lastSynced;
  SyncConflict? _conflict;
  Object? _error;
  bool _pending = false;

  AuthGateway? get _auth => ref.read(authGatewayProvider);
  CloudStore? get _store => ref.read(cloudStoreProvider);
  DateTime get _now => ref.read(clockProvider)();

  @override
  SyncStatus build() {
    ref.onDispose(() {
      _timer?.cancel();
      _retry?.cancel();
    });
    final auth = _auth;
    if (auth == null || _store == null) return const SyncStatus();
    final sub = auth.userChanges.listen(_onUser);
    ref.onDispose(sub.cancel);
    _user = auth.currentUser;
    return SyncStatus(
      phase: _user == null ? SyncPhase.signedOut : SyncPhase.idle,
      user: _user,
    );
  }

  // ---- events -----------------------------------------------------------------

  void _emit(SyncPhase phase) {
    if (!ref.mounted) return;
    state = SyncStatus(
      phase: phase,
      user: _user,
      lastSynced: _lastSynced,
      pending: _pending,
      conflict: _conflict,
      error: _error,
    );
  }

  void _onUser(CloudUser? user) {
    if (!ref.mounted) return;
    // A choice that was open belongs to the account it was found for.
    if (user?.uid != _user?.uid) _conflict = null;
    _user = user;
    if (user == null) {
      _lastSynced = null;
      _conflict = null;
      _pending = false;
      _emit(SyncPhase.signedOut);
      unawaited(_ensureUser());
      return;
    }
    final meta = _meta(user.uid);
    _lastSynced = meta?.at;
    _refreshPending();
    _emit(state.phase == SyncPhase.signedOut ? SyncPhase.idle : state.phase);
    if (!_locked) unawaited(syncNow());
  }

  /// Call after every change of the app state.
  void onStateChanged(AppState? before, AppState after) {
    if (state.phase == SyncPhase.unavailable || _locked) return;
    if (before != null) {
      final milestone = milestoneFor(before, after);
      if (milestone != null) {
        _pendingMilestone = milestone;
        _suggestAccount(milestone);
      }
    }
    unawaited(_ensureUser());
    if (_user == null) return;
    _refreshPending();
    _emit(state.phase);
    if (_pending && state.phase != SyncPhase.conflict) {
      _timer?.cancel();
      _timer = Timer(ref.read(cloudSaveDelayProvider), () => unawaited(syncNow()));
    }
  }

  /// A silent account is lost with the app, so at a milestone the learner is
  /// reminded, once a day at most, to add an email.
  void _suggestAccount(String milestone) {
    if (_user != null && !_user!.isAnonymous) return;
    final prefs = ref.read(prefsProvider);
    final today = dayKey(_now);
    if (prefs.getString(_hintDayKey) == today) return;
    prefs.setString(_hintDayKey, today);
    ref.read(accountHintProvider.notifier).show(milestone);
  }

  /// Call when the app returns to the foreground.
  void syncSoon() {
    if (_locked || _user == null || state.phase == SyncPhase.conflict) return;
    unawaited(syncNow());
  }

  /// Creates the silent account that holds the progress until the learner
  /// adds an email. Only once the first course has been started.
  Future<void> _ensureUser() async {
    final auth = _auth;
    if (auth == null || _locked || _signingIn) return;
    if (auth.currentUser != null || !ref.read(appProvider).onboarded) return;
    _signingIn = true;
    try {
      await auth.signInAnonymously();
    } on AuthProblemException catch (e) {
      _error = e;
      _emit(e.problem == AuthProblem.network ? SyncPhase.offline : SyncPhase.error);
      _scheduleRetry();
    } finally {
      _signingIn = false;
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    final delay = _retryDelays[_retryStep.clamp(0, _retryDelays.length - 1)];
    _retryStep++;
    _retry = Timer(delay, () {
      if (_user == null) {
        unawaited(_ensureUser());
      } else {
        unawaited(syncNow());
      }
    });
  }

  // ---- the sync -----------------------------------------------------------------

  /// Runs a sync now. A call during a running sync asks for one more run and
  /// waits for it.
  Future<void> syncNow() {
    if (_run != null) {
      _again = true;
      return _run!;
    }
    return _run = _loop().whenComplete(() => _run = null);
  }

  Future<void> _loop() async {
    final store = _store;
    final user = _user;
    if (store == null || user == null) return;
    _timer?.cancel();
    _retry?.cancel();
    do {
      _again = false;
      _emit(SyncPhase.syncing);
      await _reconcile(store, user.uid);
    } while (_again && _user?.uid == user.uid);
  }

  Future<void> _reconcile(CloudStore store, String uid) async {
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        final cloud = await store.read(uid);
        final local = _snapshot();
        final meta = _meta(uid);
        final dirty = meta == null || meta.fp != local.fingerprint;
        final action = decideSync(
          cloudRev: cloud?.rev,
          baseRev: meta?.baseRev,
          localDirty: dirty,
          localHasProgress: ref.read(appProvider).onboarded,
          sameContent: cloud != null && cloud.fingerprint == local.fingerprint,
        );
        switch (action) {
          case SyncAction.nothing:
            if (cloud != null) _remember(uid, cloud.rev, local.fingerprint);
            _finish();
            return;
          case SyncAction.download:
            _apply(cloud!);
            _remember(uid, cloud.rev, _snapshot().fingerprint);
            _finish();
            return;
          case SyncAction.conflict:
            _conflict = SyncConflict(cloud: cloud!, local: local);
            _emit(SyncPhase.conflict);
            return;
          case SyncAction.upload:
            try {
              final rev = await store.write(uid, local, baseRev: cloud?.rev);
              _remember(uid, rev, local.fingerprint);
              await _afterUpload(store, uid, local);
              _finish();
              return;
            } on RevMismatch {
              // Another phone wrote between our read and our write. Decide again.
              continue;
            }
        }
      }
      _error = const CloudRefused('too-many-races');
      _emit(SyncPhase.error);
    } on CloudUnavailable {
      _error = null;
      _emit(SyncPhase.offline);
      _scheduleRetry();
    } catch (e) {
      // Any other failure ends this run with a visible error instead of
      // escaping as an unhandled exception.
      _error = e;
      _emit(SyncPhase.error);
    }
  }

  void _finish() {
    _error = null;
    _conflict = null;
    _retryStep = 0;
    _lastSynced = _meta(_user?.uid ?? '')?.at ?? _now;
    _refreshPending();
    _emit(SyncPhase.idle);
    if (_pending) {
      _timer?.cancel();
      _timer = Timer(ref.read(cloudSaveDelayProvider), () => unawaited(syncNow()));
    }
  }

  /// Milestones and the first save of each day also leave a restore point.
  /// Best effort: a failure here never turns a good save into an error.
  Future<void> _afterUpload(CloudStore store, String uid, CloudSave saved) async {
    final milestone = _pendingMilestone;
    final last = _meta(uid)?.cp;
    final dailyDue = last == null ||
        _now.difference(DateTime.fromMillisecondsSinceEpoch(last, isUtc: true)) >=
            dailyCheckpointEvery;
    if (milestone == null && !dailyDue) return;
    try {
      await _checkpoint(
        store,
        uid,
        saved,
        milestone != null ? CheckpointReason.milestone : CheckpointReason.daily,
        label: milestone ?? '',
      );
      _pendingMilestone = null;
    } catch (_) {
      // Tried again after the next save.
    }
  }

  // ---- restore points -----------------------------------------------------------------

  Future<void> _checkpoint(
    CloudStore store,
    String uid,
    CloudSave save,
    CheckpointReason reason, {
    String label = '',
  }) async {
    final existing = await store.checkpoints(uid);
    await store.writeCheckpoint(
      uid,
      CloudCheckpoint(
        slot: nextCheckpointSlot(existing),
        reason: reason,
        label: label,
        save: CloudSave(
          savedAt: _now,
          appVersion: save.appVersion,
          activeCourse: save.activeCourse,
          profile: save.profile,
          courses: save.courses,
        ),
      ),
    );
    final meta = _meta(uid);
    if (meta != null) _writeMeta(meta.copyWith(cp: _now.toUtc().millisecondsSinceEpoch));
  }

  /// The restore points of the signed-in account, newest first.
  Future<List<CloudCheckpoint>> loadCheckpoints() async {
    final store = _store, user = _user;
    if (store == null || user == null) return const [];
    return store.checkpoints(user.uid);
  }

  /// Puts the progress of [point] on this phone and in the cloud. What is
  /// there now is kept as a restore point first, so this can be undone.
  Future<void> restoreCheckpoint(CloudCheckpoint point) async {
    final store = _store, user = _user;
    if (store == null || user == null) return;
    await _checkpoint(store, user.uid, _snapshot(), CheckpointReason.replaced);
    _apply(point.save);
    _refreshPending();
    await syncNow();
  }

  /// Keeps what a reset is about to erase. Throws when it cannot, so the
  /// caller can refuse the reset. With no account there is nothing to keep.
  Future<void> checkpointBeforeReset() async {
    final store = _store, user = _user;
    if (store == null || user == null) return;
    await syncNow();
    await _checkpoint(store, user.uid, _snapshot(), CheckpointReason.reset);
  }

  // ---- conflict -------------------------------------------------------------------------------

  /// Settles a conflict. The copy that loses is kept as a restore point.
  Future<void> resolveConflict({required bool useCloud}) async {
    final store = _store, user = _user, conflict = _conflict;
    if (store == null || user == null || conflict == null) return;
    final uid = user.uid;
    try {
      if (useCloud) {
        await _checkpoint(store, uid, conflict.local, CheckpointReason.replaced);
        _apply(conflict.cloud);
        _remember(uid, conflict.cloud.rev, _snapshot().fingerprint);
      } else {
        await _checkpoint(store, uid, conflict.cloud, CheckpointReason.replaced);
        final local = _snapshot();
        final rev = await store.write(uid, local, baseRev: conflict.cloud.rev);
        _remember(uid, rev, local.fingerprint);
      }
      _finish();
    } on RevMismatch {
      // The cloud changed again while the learner was deciding. Look again.
      _conflict = null;
      await syncNow();
    } on CloudUnavailable {
      _emit(SyncPhase.conflict);
      rethrow;
    }
  }

  // ---- account ------------------------------------------------------------------------------------

  /// Adds an email and password to the silent account. Progress stays.
  Future<void> createAccount(String email, String password) async {
    // Use the answer itself. The auth stream may arrive after this call ends.
    _onUser(await _auth!.linkEmail(email, password));
    await syncNow();
  }

  /// Signs in to an existing account. A copy of progress on this phone and a
  /// copy in the account lead to a [SyncPhase.conflict] the learner settles.
  Future<void> signIn(String email, String password) async {
    // Use the answer itself. The auth stream may arrive after this call ends,
    // and the sync below must already run for the new account.
    _onUser(await _auth!.signInEmail(email, password));
    await syncNow();
  }

  Future<void> sendPasswordReset(String email) => _auth!.sendPasswordReset(email);

  /// Signs out and clears this phone, once the cloud holds everything. The
  /// progress stays in the account for the next sign-in. Throws
  /// [UnsavedProgress] when the cloud does not hold it all yet.
  Future<void> signOutAndClear() async {
    final auth = _auth;
    if (auth == null) return;
    await syncNow();
    if (state.phase != SyncPhase.idle || _pending) throw const UnsavedProgress();
    _locked = true;
    _timer?.cancel();
    try {
      await auth.signOut();
      _forget();
    } finally {
      _locked = false;
    }
  }

  /// Deletes the cloud data and the account, then clears this phone. An email
  /// account needs its [password] again, as a safety check.
  Future<void> deleteAccount({String? password}) async {
    final auth = _auth, store = _store, user = _user;
    if (auth == null || store == null || user == null) return;
    _locked = true;
    _timer?.cancel();
    _retry?.cancel();
    try {
      if (!user.isAnonymous && user.email != null) {
        await auth.signInEmail(user.email!, password ?? '');
      }
      await store.deleteAll(user.uid);
      await auth.deleteUser();
      _forget();
    } finally {
      _locked = false;
    }
  }

  /// Wipes the progress on this phone and forgets the sync bookmark.
  void _forget() {
    ref.read(prefsProvider).remove(_metaKey);
    ref.read(activeCourseProvider.notifier).set(defaultLanguageId);
    ref.read(appProvider.notifier).resetAll();
    _pendingMilestone = null;
    _conflict = null;
    _error = null;
    _pending = false;
  }

  // ---- local side --------------------------------------------------------------------------------------

  /// Everything this phone knows, including languages this version cannot
  /// show yet (kept so a newer app can use them later).
  CloudSave _snapshot() {
    final active = ref.read(activeCourseProvider);
    final (profile, course) = splitState(ref.read(appProvider).toJson());
    return CloudSave(
      savedAt: _now,
      appVersion: appVersion,
      activeCourse: active,
      profile: profile,
      courses: {
        for (final e in readStash(ref.read(prefsProvider)).entries)
          if (e.key != active) e.key: e.value,
        active: course,
      },
    );
  }

  /// Replaces the progress on this phone with [save].
  void _apply(CloudSave save) {
    // The language the save was made in, if this app teaches it. Otherwise
    // the first course. A save with neither has nothing to show.
    final target = isKnownLanguage(save.activeCourse) &&
            save.courses.containsKey(save.activeCourse)
        ? save.activeCourse
        : (save.courses.containsKey(defaultLanguageId) ? defaultLanguageId : null);
    if (target == null) throw const CloudException(CloudError.noCourse);
    final AppState restored;
    try {
      restored = AppState.fromJson(save.stateFor(target)).sanitized();
    } catch (_) {
      throw const CloudException(CloudError.damaged);
    }
    writeStash(ref.read(prefsProvider), {
      for (final e in save.courses.entries)
        if (e.key != target) e.key: e.value,
    });
    ref.read(activeCourseProvider.notifier).set(target);
    ref.read(appProvider.notifier).restoreFrom(restored);
  }

  // ---- bookmark ---------------------------------------------------------------------------------------------

  _Meta? _meta(String uid) {
    final raw = ref.read(prefsProvider).getString(_metaKey);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['uid'] != uid) return null;
      return _Meta(
        uid: uid,
        baseRev: m['baseRev'] as int,
        fp: m['fp'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(m['at'] as int, isUtc: true),
        cp: m['cp'] as int?,
      );
    } catch (_) {
      return null;
    }
  }

  void _writeMeta(_Meta m) =>
      ref.read(prefsProvider).setString(_metaKey, jsonEncode(m.toJson()));

  /// Notes that phone and cloud agreed at [rev] with progress [fp].
  void _remember(String uid, int rev, String fp) {
    _writeMeta(_Meta(
      uid: uid,
      baseRev: rev,
      fp: fp,
      at: _now.toUtc(),
      cp: _meta(uid)?.cp,
    ));
  }

  void _refreshPending() {
    final uid = _user?.uid;
    if (uid == null) {
      _pending = false;
      return;
    }
    // With no bookmark the phone never agreed with the cloud, so it only has
    // something to send once a course is started. With a bookmark any change
    // counts, a reset included, so the cloud follows the phone.
    final meta = _meta(uid);
    _pending = meta == null
        ? ref.read(appProvider).onboarded
        : meta.fp != _snapshot().fingerprint;
  }
}

class _Meta {
  const _Meta({
    required this.uid,
    required this.baseRev,
    required this.fp,
    required this.at,
    this.cp,
  });

  final String uid;

  /// The cloud revision the phone last agreed with.
  final int baseRev;

  /// Fingerprint of the phone's progress at that moment.
  final String fp;
  final DateTime at;

  /// When the newest restore point was made (ms since epoch).
  final int? cp;

  _Meta copyWith({int? cp}) =>
      _Meta(uid: uid, baseRev: baseRev, fp: fp, at: at, cp: cp ?? this.cp);

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'baseRev': baseRev,
        'fp': fp,
        'at': at.millisecondsSinceEpoch,
        'cp': cp,
      };
}
