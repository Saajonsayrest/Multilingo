// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get backupTitle => 'Backup and restore';

  @override
  String get backupSettingsTile => 'Backup and restore';

  @override
  String get backupSettingsTileSubtitle => 'Keep your progress safe';

  @override
  String get backupIntro =>
      'Your progress lives only on this phone. If you uninstall the app, it is erased. Save the backup file somewhere safe, such as Files or Drive.';

  @override
  String get backupFileCard => 'Backup file';

  @override
  String backupFileName(String name) {
    return 'File name: $name';
  }

  @override
  String get backupFileHint =>
      'There is only one file. Saving again replaces the old one.';

  @override
  String get backupSaveButton => 'Save backup file';

  @override
  String get backupShareButton => 'Share backup file';

  @override
  String get backupImportButton => 'Restore from a file';

  @override
  String get backupSaved => 'Backup saved.';

  @override
  String get backupSharedReady => 'Backup file is ready to share.';

  @override
  String get backupSaveFailed => 'Could not save the backup. Please try again.';

  @override
  String get checkpointsTitle => 'Restore points';

  @override
  String get checkpointsIntro =>
      'Quick snapshots kept inside the app. They are removed if you uninstall.';

  @override
  String get checkpointsEmpty => 'No restore points yet.';

  @override
  String get checkpointCreate => 'Create a restore point';

  @override
  String get checkpointLabelField => 'Name (optional)';

  @override
  String get checkpointAuto => 'Automatic';

  @override
  String checkpointSummary(int xp, int lessons, int streak) {
    return '$xp XP, $lessons lessons, $streak day streak';
  }

  @override
  String get checkpointCreated => 'Restore point created.';

  @override
  String get checkpointDeleted => 'Restore point deleted.';

  @override
  String get checkpointRename => 'Rename';

  @override
  String get checkpointDelete => 'Delete';

  @override
  String get checkpointRestore => 'Restore';

  @override
  String get restoreConfirmTitle => 'Restore this backup?';

  @override
  String restoreConfirmBody(String date, int xp, int lessons, int streak) {
    return 'Saved $date\n$xp XP, $lessons lessons, $streak day streak.\n\nYour current progress will be replaced. A restore point of it is saved first, so you can undo this.';
  }

  @override
  String get restoreConfirmAction => 'Restore';

  @override
  String get restoreDone => 'Progress restored.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get onboardingHaveBackup => 'I already have a backup';

  @override
  String get errorUnreadable =>
      'This file cannot be read. Pick a Multilingo backup file.';

  @override
  String get errorNotMultilingo => 'This is not a Multilingo backup file.';

  @override
  String get errorTooNew =>
      'This backup was made by a newer version of the app. Please update the app first.';

  @override
  String get errorDamaged =>
      'This backup is damaged or was changed. It was not restored.';

  @override
  String get errorNoCourse => 'This backup has no progress for this course.';

  @override
  String get errorGeneric => 'Something went wrong. Nothing was changed.';
}
