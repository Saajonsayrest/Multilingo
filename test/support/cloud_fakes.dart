import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/domain/cloud_save.dart';
import 'package:multilingo/state/auth_gateway.dart';
import 'package:multilingo/state/cloud_store.dart';
import 'package:multilingo/state/cloud_sync.dart';
import 'package:multilingo/state/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The accounts every fake phone shares, like the real Firebase project.
class FakeAuthServer {
  final passwords = <String, String>{};
  final uidByEmail = <String, String>{};
  final deleted = <String>[];
  int counter = 0;
}

class FakeAuth implements AuthGateway {
  FakeAuth(this.server, {CloudUser? user}) {
    _user = user;
  }

  final FakeAuthServer server;
  final _changes = StreamController<CloudUser?>.broadcast();
  CloudUser? _user;
  bool offline = false;
  int anonymousSignIns = 0;

  void _set(CloudUser? u) {
    _user = u;
    _changes.add(u);
  }

  void _check() {
    if (offline) throw const AuthProblemException(AuthProblem.network);
  }

  @override
  CloudUser? get currentUser => _user;

  @override
  Stream<CloudUser?> get userChanges async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<CloudUser> signInAnonymously() async {
    _check();
    anonymousSignIns++;
    final u = CloudUser(uid: 'anon${++server.counter}', isAnonymous: true);
    _set(u);
    return u;
  }

  @override
  Future<CloudUser> linkEmail(String email, String password) async {
    _check();
    final current = _user!;
    if (server.passwords.containsKey(email)) {
      throw const AuthProblemException(AuthProblem.emailInUse);
    }
    if (password.length < 6) throw const AuthProblemException(AuthProblem.weakPassword);
    server.passwords[email] = password;
    server.uidByEmail[email] = current.uid;
    final u = CloudUser(uid: current.uid, email: email);
    _set(u);
    return u;
  }

  @override
  Future<CloudUser> signInEmail(String email, String password) async {
    _check();
    if (server.passwords[email] != password) {
      throw const AuthProblemException(AuthProblem.wrongCredentials);
    }
    final u = CloudUser(uid: server.uidByEmail[email]!, email: email);
    _set(u);
    return u;
  }

  @override
  Future<void> sendPasswordReset(String email) async => _check();

  @override
  Future<void> signOut() async {
    _check();
    _set(null);
  }

  @override
  Future<void> deleteUser() async {
    _check();
    final u = _user!;
    server.deleted.add(u.uid);
    if (u.email != null) {
      server.passwords.remove(u.email);
      server.uidByEmail.remove(u.email);
    }
    _set(null);
  }
}

class MemoryCloudStore implements CloudStore {
  final saves = <String, CloudSave>{};
  final points = <String, Map<int, CloudCheckpoint>>{};
  bool offline = false;
  int writes = 0;

  /// Makes the next [read] throw this.
  Object? readError;

  /// Runs just before each write. A test uses it to let "another phone" write
  /// between this phone's read and its write.
  void Function(String uid)? beforeWrite;

  void _check() {
    if (offline) throw const CloudUnavailable();
  }

  @override
  Future<CloudSave?> read(String uid) async {
    _check();
    final e = readError;
    if (e != null) throw e;
    return saves[uid];
  }

  @override
  Future<int> write(String uid, CloudSave save, {required int? baseRev}) async {
    _check();
    beforeWrite?.call(uid);
    final cur = saves[uid]?.rev;
    if (cur != baseRev) throw RevMismatch(cur);
    save.checkSize();
    final next = (cur ?? 0) + 1;
    saves[uid] = save.withRev(next);
    writes++;
    return next;
  }

  @override
  Future<List<CloudCheckpoint>> checkpoints(String uid) async {
    _check();
    final list = (points[uid] ?? {}).values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> writeCheckpoint(String uid, CloudCheckpoint checkpoint) async {
    _check();
    (points[uid] ??= {})[checkpoint.slot] = checkpoint;
  }

  @override
  Future<void> deleteAll(String uid) async {
    _check();
    saves.remove(uid);
    points.remove(uid);
  }
}

/// One phone: its own storage, account session and app, sharing the cloud.
class Phone {
  Phone._(this.container, this.prefs, this.auth, this.store);

  final ProviderContainer container;
  final SharedPreferences prefs;
  final FakeAuth auth;
  final MemoryCloudStore store;

  /// Mutable clock: tests move time forward.
  static DateTime now = DateTime(2026, 3, 2, 10);

  static Future<Phone> boot({
    required FakeAuthServer server,
    required MemoryCloudStore store,
    bool cloud = true,
    bool onboarded = true,
    CloudUser? user,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuth(server, user: user);
    final c = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
      cloudSaveDelayProvider.overrideWithValue(Duration.zero),
      if (cloud) ...[
        authGatewayProvider.overrideWithValue(auth),
        cloudStoreProvider.overrideWithValue(store),
      ],
    ]);
    addTearDown(c.dispose);
    // The same wiring main() does.
    c.listen(appProvider, (before, after) {
      c.read(cloudSyncProvider.notifier).onStateChanged(before, after);
    });
    c.listen(cloudSyncProvider, (_, _) {});
    if (onboarded) {
      c.read(appProvider.notifier).completeOnboarding(
          name: 'Tester', dailyGoalXp: 20, level: 'beginner');
    }
    final phone = Phone._(c, prefs, auth, store);
    await phone.settle();
    return phone;
  }

  CloudSync get sync => container.read(cloudSyncProvider.notifier);
  SyncStatus get status => container.read(cloudSyncProvider);
  AppController get app => container.read(appProvider.notifier);

  /// Lets timers and async work run until nothing is waiting.
  Future<void> settle() => pumpEventQueue(times: 200);

  /// Finishes the next [n] Italian lessons that are not done yet.
  Future<void> doLessons(int n) async {
    for (var i = 0; i < n; i++) {
      final done = container.read(appProvider).completedLessons;
      final next = Course.of('it').flatLessons.firstWhere((l) => !done.contains(l.id));
      app.finishSession(LessonResult(
        lessonId: next.id,
        correct: 10,
        total: 10,
        correctWordIds: [next.words.first.id],
      ));
      await settle();
    }
  }
}
