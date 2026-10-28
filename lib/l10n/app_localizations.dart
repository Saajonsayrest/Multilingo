import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('it'),
  ];

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backupTitle;

  /// No description provided for @backupSettingsTile.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backupSettingsTile;

  /// No description provided for @backupSettingsTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your progress safe'**
  String get backupSettingsTileSubtitle;

  /// No description provided for @backupIntro.
  ///
  /// In en, this message translates to:
  /// **'Your progress lives only on this phone. If you uninstall the app, it is erased. Save the backup file somewhere safe, such as Files or Drive.'**
  String get backupIntro;

  /// No description provided for @backupFileCard.
  ///
  /// In en, this message translates to:
  /// **'Backup file'**
  String get backupFileCard;

  /// No description provided for @backupFileName.
  ///
  /// In en, this message translates to:
  /// **'File name: {name}'**
  String backupFileName(String name);

  /// No description provided for @backupFileHint.
  ///
  /// In en, this message translates to:
  /// **'There is only one file. Saving again replaces the old one.'**
  String get backupFileHint;

  /// No description provided for @backupSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save backup file'**
  String get backupSaveButton;

  /// No description provided for @backupShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share backup file'**
  String get backupShareButton;

  /// No description provided for @backupImportButton.
  ///
  /// In en, this message translates to:
  /// **'Restore from a file'**
  String get backupImportButton;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved.'**
  String get backupSaved;

  /// No description provided for @backupSharedReady.
  ///
  /// In en, this message translates to:
  /// **'Backup file is ready to share.'**
  String get backupSharedReady;

  /// No description provided for @backupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the backup. Please try again.'**
  String get backupSaveFailed;

  /// No description provided for @checkpointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore points'**
  String get checkpointsTitle;

  /// No description provided for @checkpointsIntro.
  ///
  /// In en, this message translates to:
  /// **'Quick snapshots kept inside the app. They are removed if you uninstall.'**
  String get checkpointsIntro;

  /// No description provided for @checkpointsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No restore points yet.'**
  String get checkpointsEmpty;

  /// No description provided for @checkpointCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a restore point'**
  String get checkpointCreate;

  /// No description provided for @checkpointLabelField.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get checkpointLabelField;

  /// No description provided for @checkpointAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get checkpointAuto;

  /// No description provided for @checkpointSummary.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP, {lessons} lessons, {streak} day streak'**
  String checkpointSummary(int xp, int lessons, int streak);

  /// No description provided for @checkpointCreated.
  ///
  /// In en, this message translates to:
  /// **'Restore point created.'**
  String get checkpointCreated;

  /// No description provided for @checkpointDeleted.
  ///
  /// In en, this message translates to:
  /// **'Restore point deleted.'**
  String get checkpointDeleted;

  /// No description provided for @checkpointRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get checkpointRename;

  /// No description provided for @checkpointDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get checkpointDelete;

  /// No description provided for @checkpointRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get checkpointRestore;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Saved {date}\n{xp} XP, {lessons} lessons, {streak} day streak.\n\nYour current progress will be replaced. A restore point of it is saved first, so you can undo this.'**
  String restoreConfirmBody(String date, int xp, int lessons, int streak);

  /// No description provided for @restoreConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreConfirmAction;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Progress restored.'**
  String get restoreDone;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @onboardingHaveBackup.
  ///
  /// In en, this message translates to:
  /// **'I already have a backup'**
  String get onboardingHaveBackup;

  /// No description provided for @errorUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be read. Pick a Multilingo backup file.'**
  String get errorUnreadable;

  /// No description provided for @errorNotMultilingo.
  ///
  /// In en, this message translates to:
  /// **'This is not a Multilingo backup file.'**
  String get errorNotMultilingo;

  /// No description provided for @errorTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of the app. Please update the app first.'**
  String get errorTooNew;

  /// No description provided for @errorDamaged.
  ///
  /// In en, this message translates to:
  /// **'This backup is damaged or was changed. It was not restored.'**
  String get errorDamaged;

  /// No description provided for @errorNoCourse.
  ///
  /// In en, this message translates to:
  /// **'This backup has no progress for this course.'**
  String get errorNoCourse;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Nothing was changed.'**
  String get errorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
