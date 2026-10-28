import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multilingo/domain/cloud_save.dart';
import 'package:multilingo/domain/state_split.dart';
import 'package:multilingo/state/app_state.dart';

import 'support/full_state.dart';

CloudSave saveOf(AppState s, {int rev = 1, String active = 'it'}) {
  final (profile, course) = splitState(s.toJson());
  return CloudSave(
    rev: rev,
    savedAt: DateTime.utc(2026, 3, 2, 10),
    appVersion: '0.1.0',
    activeCourse: active,
    profile: profile,
    courses: {active: course},
  );
}

/// What Firestore does to a document: it stores plain data and hands back new
/// maps, in its own key order.
Map<String, dynamic> viaTheWire(Map<String, dynamic> map) =>
    jsonDecode(jsonEncode(map)) as Map<String, dynamic>;

void main() {
  group('a cloud document', () {
    test('every saved field survives the trip', () {
      final original = everything();
      final back = CloudSave.fromMap(viaTheWire(saveOf(original, rev: 4).toMap()));
      expect(back.rev, 4);
      final restored = AppState.fromJson(back.stateFor('it'));
      expect(jsonEncode(restored.toJson()), jsonEncode(original.toJson()));
    });

    test('equal progress has an equal fingerprint, whatever the key order', () {
      final a = saveOf(everything());
      final b = CloudSave.fromMap(viaTheWire(saveOf(everything(), rev: 9).toMap()));
      expect(b.fingerprint, a.fingerprint);
    });

    test('other progress has another fingerprint', () {
      final a = saveOf(everything());
      final b = saveOf(everything()..xp += 1);
      final c = saveOf(everything(), active: 'de');
      expect(b.fingerprint, isNot(a.fingerprint));
      expect(c.fingerprint, isNot(a.fingerprint));
    });

    test('a newer layout is refused, not guessed', () {
      final map = saveOf(everything()).toMap()..['schema'] = cloudSchema + 1;
      expect(
        () => CloudSave.fromMap(map),
        throwsA(isA<CloudException>().having((e) => e.error, 'error', CloudError.tooNew)),
      );
    });

    for (final (name, change) in <(String, void Function(Map<String, dynamic>))>[
      ('no schema', (m) => m.remove('schema')),
      ('schema zero', (m) => m['schema'] = 0),
      ('no revision', (m) => m['rev'] = 0),
      ('no time', (m) => m['savedAt'] = 'yesterday'),
      ('no profile', (m) => m.remove('profile')),
      ('no courses', (m) => m['courses'] = <String, dynamic>{}),
      ('active course missing', (m) => m['activeCourse'] = 'xx'),
      ('a course that is not a map', (m) => m['courses'] = {'it': 5}),
    ]) {
      test('damaged: $name', () {
        final map = viaTheWire(saveOf(everything()).toMap());
        change(map);
        expect(
          () => CloudSave.fromMap(map),
          throwsA(isA<CloudException>().having((e) => e.error, 'error', CloudError.damaged)),
        );
      });
    }

    test('a save too large for one document is refused before sending', () {
      final big = saveOf(everything()..wordBox = {
        for (var i = 0; i < 60000; i++) 'a-long-word-id-number-$i': 3,
      });
      expect(
        big.checkSize,
        throwsA(isA<CloudException>().having((e) => e.error, 'error', CloudError.tooBig)),
      );
      saveOf(everything()).checkSize();
    });
  });

  group('restore points', () {
    CloudCheckpoint point(int slot, int minute) => CloudCheckpoint(
          slot: slot,
          reason: CheckpointReason.daily,
          label: '',
          save: CloudSave(
            savedAt: DateTime.utc(2026, 3, 2, 10, minute),
            appVersion: '0.1.0',
            activeCourse: 'it',
            profile: const {},
            courses: const {'it': {}},
          ),
        );

    test('the first free slot is used, then the oldest is replaced', () {
      expect(nextCheckpointSlot(const []), 0);
      expect(nextCheckpointSlot([point(0, 1), point(2, 2)]), 1);
      final full = [for (var i = 0; i < checkpointSlots; i++) point(i, 10 - i)];
      expect(nextCheckpointSlot(full), checkpointSlots - 1, reason: 'minute 6 is the oldest');
    });

    test('a point carries its reason and name, and no revision', () {
      final map = CloudCheckpoint(
        slot: 3,
        reason: CheckpointReason.milestone,
        label: '  10 lessons done  ',
        save: saveOf(everything()),
      ).toMap();
      expect(map.containsKey('rev'), isFalse);
      expect(map['reason'], 'milestone');
      expect(map['label'], '10 lessons done');
      final back = CloudCheckpoint.fromDoc('c3', viaTheWire(map));
      expect(back.slot, 3);
      expect(back.reason, CheckpointReason.milestone);
      expect(back.label, '10 lessons done');
    });

    test('an unknown reason is read as a daily copy', () {
      final map = viaTheWire(CloudCheckpoint(
        slot: 0,
        reason: CheckpointReason.reset,
        label: '',
        save: saveOf(everything()),
      ).toMap())
        ..['reason'] = 'from-the-future';
      expect(CloudCheckpoint.fromDoc('c0', map).reason, CheckpointReason.daily);
    });

    test('a document outside the five slots is not a restore point', () {
      final map = viaTheWire(CloudCheckpoint(
        slot: 0,
        reason: CheckpointReason.daily,
        label: '',
        save: saveOf(everything()),
      ).toMap());
      for (final id in ['c5', 'c-1', 'x0', 'c00']) {
        expect(() => CloudCheckpoint.fromDoc(id, map), throwsA(isA<CloudException>()));
      }
    });
  });

  group('deciding what a sync does', () {
    SyncAction decide({
      int? cloud,
      int? base,
      bool dirty = false,
      bool progress = true,
      bool same = false,
    }) =>
        decideSync(
          cloudRev: cloud,
          baseRev: base,
          localDirty: dirty,
          localHasProgress: progress,
          sameContent: same,
        );

    test('no cloud save yet', () {
      expect(decide(), SyncAction.upload);
      expect(decide(progress: false), SyncAction.nothing);
    });

    test('this phone never met this account', () {
      expect(decide(cloud: 3), SyncAction.conflict);
      expect(decide(cloud: 3, progress: false), SyncAction.download);
      expect(decide(cloud: 3, same: true), SyncAction.nothing);
    });

    test('both agreed at the same revision', () {
      expect(decide(cloud: 3, base: 3), SyncAction.nothing);
      expect(decide(cloud: 3, base: 3, dirty: true), SyncAction.upload);
    });

    test('the cloud moved on', () {
      expect(decide(cloud: 5, base: 3), SyncAction.download);
      expect(decide(cloud: 5, base: 3, dirty: true), SyncAction.conflict);
      expect(decide(cloud: 5, base: 3, dirty: true, same: true), SyncAction.nothing);
    });

    test('a cloud that went back counts as moved', () {
      expect(decide(cloud: 1, base: 3), SyncAction.download);
      expect(decide(cloud: 1, base: 3, dirty: true), SyncAction.conflict);
    });

    test('a reset phone still sends, so the cloud follows', () {
      expect(decide(cloud: 3, base: 3, dirty: true, progress: false), SyncAction.upload);
    });
  });
}
