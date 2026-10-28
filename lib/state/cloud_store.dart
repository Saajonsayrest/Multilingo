import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cloud_save.dart';

/// No connection, or the server did not answer in time. Try again later.
class CloudUnavailable implements Exception {
  const CloudUnavailable();

  @override
  String toString() => 'CloudUnavailable';
}

/// Someone else wrote to the save since this phone last looked.
class RevMismatch implements Exception {
  const RevMismatch(this.cloudRev);

  final int? cloudRev;

  @override
  String toString() => 'RevMismatch($cloudRev)';
}

/// The server said no (rules, sign-in, quota). Retrying will not help.
class CloudRefused implements Exception {
  const CloudRefused(this.code);

  final String code;

  @override
  String toString() => 'CloudRefused($code)';
}

/// Where the cloud save lives. An interface so tests can replace Firestore.
abstract class CloudStore {
  /// The save of [uid], read from the server (never from a stale cache).
  /// Null when the account has none yet.
  Future<CloudSave?> read(String uid);

  /// Stores [save] and returns its new revision. Throws [RevMismatch] when
  /// the stored revision is not [baseRev] (null means "no save yet").
  Future<int> write(String uid, CloudSave save, {required int? baseRev});

  /// The restore points, newest first.
  Future<List<CloudCheckpoint>> checkpoints(String uid);

  Future<void> writeCheckpoint(String uid, CloudCheckpoint checkpoint);

  /// Removes the save and every restore point of [uid].
  Future<void> deleteAll(String uid);
}

/// Null when Firebase is not set up (tests, or a build without its config).
/// main() overrides it once Firebase has started.
final cloudStoreProvider = Provider<CloudStore?>((ref) => null);

const _timeout = Duration(seconds: 20);

class FirestoreCloudStore implements CloudStore {
  FirestoreCloudStore([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _save(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _points(String uid) =>
      _save(uid).collection('checkpoints');

  Future<T> _guard<T>(Future<T> Function() job) async {
    try {
      return await job().timeout(_timeout);
    } on TimeoutException {
      throw const CloudUnavailable();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'unavailable' || 'deadline-exceeded' || 'aborted' || 'cancelled':
          throw const CloudUnavailable();
        default:
          throw CloudRefused(e.code);
      }
    }
  }

  @override
  Future<CloudSave?> read(String uid) => _guard(() async {
        final snap = await _save(uid).get(const GetOptions(source: Source.server));
        final data = snap.data();
        return data == null ? null : CloudSave.fromMap(data);
      });

  @override
  Future<int> write(String uid, CloudSave save, {required int? baseRev}) =>
      _guard(() {
        save.checkSize();
        final ref = _save(uid);
        return _db.runTransaction<int>(
          (tx) async {
            final snap = await tx.get(ref);
            final stored = snap.data()?['rev'];
            final cloudRev = stored is int ? stored : null;
            if (cloudRev != baseRev) throw RevMismatch(cloudRev);
            final next = (cloudRev ?? 0) + 1;
            tx.set(ref, save.withRev(next).toMap());
            return next;
          },
          timeout: _timeout,
          maxAttempts: 3,
        );
      });

  @override
  Future<List<CloudCheckpoint>> checkpoints(String uid) => _guard(() async {
        final snap = await _points(uid).get(const GetOptions(source: Source.server));
        final out = <CloudCheckpoint>[];
        for (final d in snap.docs) {
          try {
            out.add(CloudCheckpoint.fromDoc(d.id, d.data()));
          } on CloudException {
            // Skip an unreadable entry instead of hiding all the others.
          }
        }
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return out;
      });

  @override
  Future<void> writeCheckpoint(String uid, CloudCheckpoint checkpoint) =>
      _guard(() {
        checkpoint.save.checkSize();
        return _points(uid).doc(checkpoint.docId).set(checkpoint.toMap());
      });

  @override
  Future<void> deleteAll(String uid) => _guard(() {
        final batch = _db.batch()..delete(_save(uid));
        for (var i = 0; i < checkpointSlots; i++) {
          batch.delete(_points(uid).doc('c$i'));
        }
        return batch.commit();
      });
}
