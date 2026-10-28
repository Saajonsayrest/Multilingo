// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountTitle => 'Account and cloud save';

  @override
  String get accountTileSubtitle => 'Keep your progress safe';

  @override
  String get cloudUnavailable =>
      'Cloud save is not available in this build. Your progress stays on this phone.';

  @override
  String get cloudSignedOut => 'Not saved to the cloud yet.';

  @override
  String get cloudSyncing => 'Saving...';

  @override
  String cloudSaved(String when) {
    return 'Saved to the cloud $when';
  }

  @override
  String get cloudPending => 'Changes will be saved in a moment.';

  @override
  String get cloudOffline =>
      'No connection. Your progress is safe on this phone and will be saved when you are online.';

  @override
  String get cloudError =>
      'Could not save to the cloud. Tap Save now to try again.';

  @override
  String get cloudConflict =>
      'This phone and your account hold different progress. Choose which to keep.';

  @override
  String get cloudSaveNow => 'Save now';

  @override
  String get cloudChoose => 'Choose';

  @override
  String get accountIntroAnonymous =>
      'Your progress is saved to the cloud on its own. Add an email and a password to get it back on a new phone or after you reinstall the app.';

  @override
  String accountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get accountEmail => 'Email';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordHint => 'At least 8 characters';

  @override
  String get accountCreate => 'Create account';

  @override
  String get accountHaveAccount => 'I already have an account';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountForgot => 'Forgot password?';

  @override
  String get accountResetSent =>
      'If this email has an account, a link to reset the password is on its way.';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutBody =>
      'Your progress stays safe in your account and is removed from this phone. Sign in again to get it back.';

  @override
  String get accountDelete => 'Delete account and data';

  @override
  String get accountDeleteBody =>
      'This erases your account, your cloud save and your progress on this phone. It cannot be undone.';

  @override
  String get accountDeletePassword => 'Password to confirm';

  @override
  String get accountDeleted => 'Account deleted.';

  @override
  String get pointsTitle => 'Restore points';

  @override
  String get pointsIntro =>
      'Copies kept in your account. They are made at milestones, once a day, and before a reset or a restore.';

  @override
  String get pointsEmpty => 'No restore points yet.';

  @override
  String get pointDaily => 'Daily copy';

  @override
  String get pointReplaced => 'Before a restore';

  @override
  String get pointReset => 'Before a reset';

  @override
  String pointSummary(int xp, int lessons, int streak) {
    return '$xp XP, $lessons lessons, $streak day streak';
  }

  @override
  String get pointRestore => 'Restore';

  @override
  String get restoreConfirmTitle => 'Restore this copy?';

  @override
  String restoreConfirmBody(String date, int xp, int lessons, int streak) {
    return 'Saved $date\n$xp XP, $lessons lessons, $streak day streak.\n\nYour current progress will be replaced. A restore point of it is saved first, so you can undo this.';
  }

  @override
  String get restoreConfirmAction => 'Restore';

  @override
  String get restoreDone => 'Progress restored.';

  @override
  String get conflictTitle => 'Which progress do you want to keep?';

  @override
  String get conflictBody =>
      'This phone and your account hold different progress. The one you do not choose is kept as a restore point.';

  @override
  String get conflictPhone => 'This phone';

  @override
  String get conflictAccount => 'Your account';

  @override
  String get conflictUseAccount => 'Use the account progress';

  @override
  String get conflictUsePhone => 'Keep this phone progress';

  @override
  String get conflictLater => 'Decide later';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInNoProgress =>
      'This account has no saved progress yet. Finish setting up and it will be saved here.';

  @override
  String get onboardingHaveAccount => 'I already have an account';

  @override
  String accountHint(String milestone) {
    return '$milestone! Create an account so you never lose your progress. Tap here.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get errorInvalidEmail => 'That email address does not look right.';

  @override
  String get errorWeakPassword => 'Use a password with at least 8 characters.';

  @override
  String get errorEmailInUse =>
      'This email already has an account. Use Sign in instead.';

  @override
  String get errorWrongCredentials => 'The email or the password is wrong.';

  @override
  String get errorNetwork =>
      'No connection. Please try again when you are online.';

  @override
  String get errorTooMany => 'Too many tries. Please wait a few minutes.';

  @override
  String get errorDisabled => 'This account has been turned off.';

  @override
  String get errorNotAllowed => 'Email sign-in is not turned on for this app.';

  @override
  String get errorRecentLogin => 'Please sign in again and then retry.';

  @override
  String get errorUnsaved =>
      'Your latest progress is not in the cloud yet. Connect to the internet and try again.';

  @override
  String get errorTooNew =>
      'This save was made by a newer version of the app. Please update the app first.';

  @override
  String get errorDamaged => 'This save is damaged. It was not restored.';

  @override
  String get errorNoCourse => 'This save has no progress for this course.';

  @override
  String get errorTooBig => 'Your progress is too large to save to the cloud.';

  @override
  String get errorRefused =>
      'The cloud did not accept the request. Please try again later.';

  @override
  String get errorGeneric => 'Something went wrong. Nothing was changed.';

  @override
  String get resetNeedsOnline =>
      'Connect to the internet to reset, so your progress can be restored if you change your mind.';
}
