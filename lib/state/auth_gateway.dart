import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in account, as far as the app cares.
class CloudUser {
  const CloudUser({required this.uid, this.email, this.isAnonymous = false});

  final String uid;
  final String? email;

  /// True until the learner adds an email and password.
  final bool isAnonymous;
}

/// Why a sign-in step failed, in words the app can translate.
enum AuthProblem {
  invalidEmail,
  weakPassword,
  emailInUse,
  wrongCredentials,
  network,
  tooManyRequests,
  disabled,
  notAllowed,

  /// Deleting an account needs a sign-in from the last few minutes.
  recentLogin,
  other,
}

class AuthProblemException implements Exception {
  const AuthProblemException(this.problem);

  final AuthProblem problem;

  @override
  String toString() => 'AuthProblemException(${problem.name})';
}

/// The few things the app needs from Firebase Auth. An interface so tests can
/// replace it without Firebase.
abstract class AuthGateway {
  CloudUser? get currentUser;

  /// Emits the account now and whenever it changes (sign-in, sign-out, link).
  Stream<CloudUser?> get userChanges;

  Future<CloudUser> signInAnonymously();

  /// Turns the anonymous account into an email account. Progress stays.
  Future<CloudUser> linkEmail(String email, String password);

  Future<CloudUser> signInEmail(String email, String password);

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Future<void> deleteUser();
}

/// Null when Firebase is not set up (tests, or a build without its config).
/// main() overrides it once Firebase has started.
final authGatewayProvider = Provider<AuthGateway?>((ref) => null);

AuthProblem authProblemFor(String code) => switch (code) {
      'invalid-email' => AuthProblem.invalidEmail,
      'weak-password' => AuthProblem.weakPassword,
      'email-already-in-use' || 'credential-already-in-use' => AuthProblem.emailInUse,
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' =>
        AuthProblem.wrongCredentials,
      'network-request-failed' => AuthProblem.network,
      'too-many-requests' => AuthProblem.tooManyRequests,
      'user-disabled' => AuthProblem.disabled,
      'operation-not-allowed' => AuthProblem.notAllowed,
      'requires-recent-login' => AuthProblem.recentLogin,
      _ => AuthProblem.other,
    };

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static CloudUser? _wrap(User? u) => u == null
      ? null
      : CloudUser(uid: u.uid, email: u.email, isAnonymous: u.isAnonymous);

  Future<T> _guard<T>(Future<T> Function() job) async {
    try {
      return await job();
    } on FirebaseAuthException catch (e) {
      throw AuthProblemException(authProblemFor(e.code));
    }
  }

  @override
  CloudUser? get currentUser => _wrap(_auth.currentUser);

  @override
  Stream<CloudUser?> get userChanges => _auth.userChanges().map(_wrap);

  @override
  Future<CloudUser> signInAnonymously() => _guard(() async {
        final cred = await _auth.signInAnonymously();
        return _wrap(cred.user ?? _auth.currentUser)!;
      });

  @override
  Future<CloudUser> linkEmail(String email, String password) => _guard(() async {
        final user = _auth.currentUser;
        if (user == null) throw const AuthProblemException(AuthProblem.other);
        final cred = await user.linkWithCredential(
          EmailAuthProvider.credential(email: email.trim(), password: password),
        );
        return _wrap(cred.user ?? _auth.currentUser)!;
      });

  @override
  Future<CloudUser> signInEmail(String email, String password) => _guard(() async {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _wrap(cred.user ?? _auth.currentUser)!;
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  @override
  Future<void> deleteUser() => _guard(() async => _auth.currentUser?.delete());
}
