import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/data/course.dart';
import 'package:multilingo/domain/cloud_save.dart';
import 'package:multilingo/state/auth_gateway.dart';
import 'package:multilingo/state/cloud_store.dart';
import 'package:multilingo/state/cloud_sync.dart';
import 'package:multilingo/state/controller.dart';
import 'package:multilingo/state/course_state.dart';

import 'support/cloud_fakes.dart';

const _email = 'learner@example.com';
const _pw = 'correct-horse';

void main() {
  late FakeAuthServer server;
  late MemoryCloudStore store;

  setUp(() {
    server = FakeAuthServer();
    store = MemoryCloudStore();
    Phone.now = DateTime(2026, 3, 2, 10);
  });

  Future<Phone> boot({bool onboarded = true, bool cloud = true}) =>
      Phone.boot(server: server, store: store, onboarded: onboarded, cloud: cloud);

  /// A phone with an email account and [lessons] finished lessons in the cloud.
  Future<Phone> accountWith(int lessons) async {
    final p = await boot();
    await p.sync.createAccount(_email, _pw);
    await p.doLessons(lessons);
    await p.settle();
    return p;
  }

  group('saving', () {
    test('finishing the first-run screens saves progress to the cloud', () async {
      final p = await boot();
      final user = p.auth.currentUser!;
      expect(user.isAnonymous, isTrue);
      final save = store.saves[user.uid]!;
      expect(save.rev, 1);
      expect(save.profile['name'], 'Tester');
      expect(p.status.phase, SyncPhase.idle);
      expect(p.status.pending, isFalse);
      expect(p.status.lastSynced, isNotNull);
    });

    test('nothing is created or sent before the first course is started', () async {
      final p = await boot(onboarded: false);
      expect(p.auth.anonymousSignIns, 0);
      expect(store.writes, 0);
      expect(p.status.phase, SyncPhase.signedOut);
    });

    test('a change is sent and counts one revision up', () async {
      final p = await boot();
      await p.doLessons(1);
      final save = store.saves[p.auth.currentUser!.uid]!;
      expect(save.rev, 2);
      expect(save.courses['it']!['completedLessons'], hasLength(1));
      expect(p.status.pending, isFalse);
    });

    test('a build without Firebase keeps working on the phone', () async {
      final p = await boot(cloud: false);
      expect(p.status.phase, SyncPhase.unavailable);
      await p.doLessons(2);
      expect(p.container.read(appProvider).completedLessons, hasLength(2));
      expect(store.writes, 0);
    });

    test('both languages are saved and come back on another phone', () async {
      final a = await accountWith(1);
      a.app.switchCourse('de');
      await a.settle();
      final deLesson = Course.of('de').flatLessons.first;
      a.app.finishSession(LessonResult(
        lessonId: deLesson.id,
        correct: 10,
        total: 10,
        correctWordIds: [deLesson.words.first.id],
      ));
      await a.settle();

      final b = await boot(onboarded: false);
      await b.sync.signIn(_email, _pw);
      expect(b.container.read(activeCourseProvider), 'de');
      expect(b.container.read(appProvider).completedLessons, {deLesson.id});
      b.app.switchCourse('it');
      expect(b.container.read(appProvider).completedLessons, hasLength(1));
    });
  });

  group('restore points', () {
    test('the first save of a day leaves one, a second the same day does not', () async {
      final p = await boot();
      final uid = p.auth.currentUser!.uid;
      int daily() =>
          store.points[uid]!.values.where((c) => c.reason == CheckpointReason.daily).length;
      expect(daily(), 1);
      await p.doLessons(1);
      expect(daily(), 1, reason: 'same day');
      Phone.now = Phone.now.add(const Duration(hours: 25));
      await p.doLessons(1);
      expect(daily(), 2);
    });

    // A milestone is named after the first thing that happened, so a badge
    // earned on the same lesson gives the name "New badge". The point still
    // holds the progress of that moment.
    test('every 5th lesson leaves a restore point with a name', () async {
      final p = await boot();
      await p.doLessons(5);
      final points = await p.sync.loadCheckpoints();
      final milestone = points.firstWhere(
        (c) => c.reason == CheckpointReason.milestone && summarize(c.save).lessons == 5,
      );
      expect(milestone.label, isNotEmpty);
    });

    test('restoring puts the old progress back and keeps what it replaced', () async {
      final p = await boot();
      await p.doLessons(5);
      final milestone = (await p.sync.loadCheckpoints()).firstWhere(
        (c) => c.reason == CheckpointReason.milestone && summarize(c.save).lessons == 5,
      );
      await p.doLessons(2);
      expect(p.container.read(appProvider).completedLessons, hasLength(7));

      await p.sync.restoreCheckpoint(milestone);
      await p.settle();
      expect(p.container.read(appProvider).completedLessons, hasLength(5));
      final cloud = store.saves[p.auth.currentUser!.uid]!;
      expect(summarize(cloud).lessons, 5, reason: 'the cloud follows the restore');
      final undo = (await p.sync.loadCheckpoints())
          .firstWhere((c) => c.reason == CheckpointReason.replaced);
      expect(summarize(undo.save).lessons, 7);
    });

    test('a restore point never outlives the five slots', () async {
      final p = await boot();
      for (var i = 0; i < 8; i++) {
        Phone.now = Phone.now.add(const Duration(hours: 25));
        await p.doLessons(1);
      }
      expect(store.points[p.auth.currentUser!.uid], hasLength(checkpointSlots));
    });

    test('a reset first keeps what it erases, and is refused offline', () async {
      final p = await boot();
      await p.doLessons(2);
      await p.sync.checkpointBeforeReset();
      final point = (await p.sync.loadCheckpoints())
          .firstWhere((c) => c.reason == CheckpointReason.reset);
      expect(summarize(point.save).lessons, 2);

      store.offline = true;
      await expectLater(p.sync.checkpointBeforeReset(), throwsA(isA<CloudUnavailable>()));
    });

    test('a reset with no cloud account needs nothing', () async {
      final p = await boot(cloud: false);
      await p.sync.checkpointBeforeReset();
    });
  });

  group('no connection', () {
    test('progress stays on the phone and is sent later', () async {
      final p = await boot();
      final uid = p.auth.currentUser!.uid;
      store.offline = true;
      await p.doLessons(2);
      expect(p.status.phase, SyncPhase.offline);
      expect(p.status.pending, isTrue);
      expect(store.saves[uid]!.rev, 1);

      store.offline = false;
      await p.sync.syncNow();
      expect(p.status.phase, SyncPhase.idle);
      expect(p.status.pending, isFalse);
      expect(summarize(store.saves[uid]!).lessons, 2);
    });

    test('no account can be made offline, and it is made on the next change', () async {
      final p = await boot(onboarded: false);
      p.auth.offline = true;
      p.app.completeOnboarding(name: 'T', dailyGoalXp: 20, level: 'beginner');
      await p.settle();
      expect(p.auth.currentUser, isNull);
      expect(p.status.phase, SyncPhase.offline);

      // A retry timer normally does this. Here the next change does.
      p.auth.offline = false;
      await p.doLessons(1);
      expect(p.auth.currentUser, isNotNull);
      expect(store.saves[p.auth.currentUser!.uid], isNotNull);
    });

    test('a newer save is refused and nothing on the phone changes', () async {
      final p = await accountWith(2);
      store.readError = const CloudException(CloudError.tooNew);
      await p.sync.syncNow();
      expect(p.status.phase, SyncPhase.error);
      expect(p.status.error, isA<CloudException>());
      expect(p.container.read(appProvider).completedLessons, hasLength(2));
    });
  });

  group('two phones', () {
    test('a phone with nothing takes the account progress', () async {
      final a = await accountWith(3);
      final b = await boot(onboarded: false);
      await b.sync.signIn(_email, _pw);
      expect(b.container.read(appProvider).onboarded, isTrue);
      expect(b.container.read(appProvider).completedLessons, hasLength(3));
      expect(b.status.phase, SyncPhase.idle);
      expect(a.status.phase, SyncPhase.idle);
    });

    test('a signed-in account with no save yet keeps the phone progress', () async {
      // The account exists but has never saved anything.
      server.passwords[_email] = _pw;
      server.uidByEmail[_email] = 'empty-account';
      final p = await boot();
      await p.doLessons(2);
      await p.sync.signIn(_email, _pw);
      expect(p.status.phase, SyncPhase.idle);
      expect(summarize(store.saves['empty-account']!).lessons, 2);
    });

    test('a quiet phone follows the other one', () async {
      final a = await accountWith(1);
      final b = await boot(onboarded: false);
      await b.sync.signIn(_email, _pw);
      await a.doLessons(2);
      final rev = store.saves[a.auth.currentUser!.uid]!.rev;
      await b.sync.syncNow();
      expect(b.container.read(appProvider).completedLessons, hasLength(3));
      expect(b.status.pending, isFalse, reason: 'following is not a change to send');
      await b.settle();
      expect(store.saves[a.auth.currentUser!.uid]!.rev, rev, reason: 'no echo write');
    });

    test('both phones changed: the learner chooses, nothing is lost', () async {
      final a = await accountWith(1);
      final b = await boot(onboarded: false);
      await b.sync.signIn(_email, _pw);

      store.offline = true;
      await b.doLessons(1);
      store.offline = false;
      await a.doLessons(2);
      await b.sync.syncNow();
      expect(b.status.phase, SyncPhase.conflict);
      expect(b.status.conflict!.local.rev, 0);
      expect(summarize(b.status.conflict!.cloud).lessons, 3);
      expect(summarize(b.status.conflict!.local).lessons, 2);

      await b.sync.resolveConflict(useCloud: true);
      expect(b.status.phase, SyncPhase.idle);
      expect(b.container.read(appProvider).completedLessons, hasLength(3));
      final kept = (await b.sync.loadCheckpoints())
          .firstWhere((c) => c.reason == CheckpointReason.replaced);
      expect(summarize(kept.save).lessons, 2, reason: 'the losing copy is kept');
    });

    test('keeping the phone replaces the account and keeps the old one', () async {
      final a = await accountWith(4);
      final b = await boot();
      await b.doLessons(1);
      await b.sync.signIn(_email, _pw);
      expect(b.status.phase, SyncPhase.conflict, reason: 'two different histories');

      await b.sync.resolveConflict(useCloud: false);
      expect(b.status.phase, SyncPhase.idle);
      final uid = a.auth.currentUser!.uid;
      expect(summarize(store.saves[uid]!).lessons, 1);
      final kept = (await b.sync.loadCheckpoints())
          .firstWhere((c) => c.reason == CheckpointReason.replaced);
      expect(summarize(kept.save).lessons, 4);
    });

    test('another phone writing in between is noticed, not overwritten', () async {
      final p = await accountWith(1);
      final uid = p.auth.currentUser!.uid;
      store.offline = true;
      await p.doLessons(1);
      store.offline = false;
      store.beforeWrite = (id) {
        // Another phone saves just after this one has read the cloud.
        store.beforeWrite = null;
        final cur = store.saves[id]!;
        store.saves[id] = CloudSave(
          rev: cur.rev + 1,
          savedAt: cur.savedAt,
          appVersion: cur.appVersion,
          activeCourse: cur.activeCourse,
          profile: {...cur.profile, 'xp': 999},
          courses: cur.courses,
        );
      };
      await p.sync.syncNow();
      expect(p.status.phase, SyncPhase.conflict);
      expect(store.saves[uid]!.profile['xp'], 999, reason: 'the other write survived');
    });
  });

  group('account', () {
    test('adding an email keeps the same account and the same progress', () async {
      final p = await boot();
      final before = p.auth.currentUser!.uid;
      await p.sync.createAccount(_email, _pw);
      await p.settle();
      expect(p.auth.currentUser!.uid, before);
      expect(p.auth.currentUser!.isAnonymous, isFalse);
      expect(p.status.user!.email, _email);
      expect(p.status.phase, SyncPhase.idle);
    });

    test('an email that is taken is refused', () async {
      await accountWith(1);
      final other = await boot();
      await expectLater(
        other.sync.createAccount(_email, _pw),
        throwsA(isA<AuthProblemException>()
            .having((e) => e.problem, 'problem', AuthProblem.emailInUse)),
      );
    });

    test('a wrong password changes nothing', () async {
      await accountWith(1);
      final b = await boot(onboarded: false);
      await expectLater(
        b.sync.signIn(_email, 'nope'),
        throwsA(isA<AuthProblemException>()
            .having((e) => e.problem, 'problem', AuthProblem.wrongCredentials)),
      );
      expect(b.container.read(appProvider).onboarded, isFalse);
    });

    test('signing out waits for the cloud, then clears the phone', () async {
      final p = await accountWith(2);
      final uid = p.auth.currentUser!.uid;

      store.offline = true;
      await p.doLessons(1);
      await expectLater(p.sync.signOutAndClear(), throwsA(isA<UnsavedProgress>()));
      expect(p.container.read(appProvider).completedLessons, hasLength(3));
      expect(p.auth.currentUser, isNotNull);

      store.offline = false;
      await p.sync.signOutAndClear();
      await p.settle();
      expect(p.auth.currentUser, isNull);
      expect(p.container.read(appProvider).onboarded, isFalse);
      expect(p.prefs.getString('multilingo.cloud.v1'), isNull);
      expect(p.auth.anonymousSignIns, 1, reason: 'no new silent account after sign-out');
      expect(summarize(store.saves[uid]!).lessons, 3, reason: 'the account keeps it');

      await p.sync.signIn(_email, _pw);
      expect(p.container.read(appProvider).completedLessons, hasLength(3));
    });

    test('deleting needs the password, then removes cloud data and the phone copy', () async {
      final p = await accountWith(2);
      final uid = p.auth.currentUser!.uid;

      await expectLater(
        p.sync.deleteAccount(password: 'wrong'),
        throwsA(isA<AuthProblemException>()),
      );
      expect(store.saves[uid], isNotNull);

      await p.sync.deleteAccount(password: _pw);
      await p.settle();
      expect(store.saves[uid], isNull);
      expect(store.points[uid], isNull);
      expect(server.deleted, contains(uid));
      expect(p.container.read(appProvider).onboarded, isFalse);
      expect(p.auth.anonymousSignIns, 1);
    });

    test('a silent account can be deleted without a password', () async {
      final p = await boot();
      final uid = p.auth.currentUser!.uid;
      await p.sync.deleteAccount();
      expect(store.saves[uid], isNull);
      expect(server.deleted, contains(uid));
    });
  });

  group('the reminder to add an email', () {
    test('shows once a day for a silent account, never for an email account', () async {
      final p = await boot();
      await p.doLessons(1);
      expect(p.container.read(accountHintProvider), 'New badge', reason: 'the first badge');
      p.container.read(accountHintProvider.notifier).clear();
      await p.doLessons(4);
      expect(p.container.read(accountHintProvider), isNull, reason: 'already told today');

      Phone.now = Phone.now.add(const Duration(days: 1));
      await p.doLessons(5);
      expect(p.container.read(accountHintProvider), isNotNull);

      p.container.read(accountHintProvider.notifier).clear();
      await p.sync.createAccount(_email, _pw);
      Phone.now = Phone.now.add(const Duration(days: 1));
      await p.doLessons(5);
      expect(p.container.read(accountHintProvider), isNull);
    });
  });
}
