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

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account and cloud save'**
  String get accountTitle;

  /// No description provided for @accountTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your progress safe'**
  String get accountTileSubtitle;

  /// No description provided for @cloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud save is not available in this build. Your progress stays on this phone.'**
  String get cloudUnavailable;

  /// No description provided for @cloudSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Not saved to the cloud yet.'**
  String get cloudSignedOut;

  /// No description provided for @cloudSyncing.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get cloudSyncing;

  /// No description provided for @cloudSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to the cloud {when}'**
  String cloudSaved(String when);

  /// No description provided for @cloudPending.
  ///
  /// In en, this message translates to:
  /// **'Changes will be saved in a moment.'**
  String get cloudPending;

  /// No description provided for @cloudOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Your progress is safe on this phone and will be saved when you are online.'**
  String get cloudOffline;

  /// No description provided for @cloudError.
  ///
  /// In en, this message translates to:
  /// **'Could not save to the cloud. Tap Save now to try again.'**
  String get cloudError;

  /// No description provided for @cloudConflict.
  ///
  /// In en, this message translates to:
  /// **'This phone and your account hold different progress. Choose which to keep.'**
  String get cloudConflict;

  /// No description provided for @cloudSaveNow.
  ///
  /// In en, this message translates to:
  /// **'Save now'**
  String get cloudSaveNow;

  /// No description provided for @cloudChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get cloudChoose;

  /// No description provided for @accountIntroAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved to the cloud on its own. Add an email and a password to get it back on a new phone or after you reinstall the app.'**
  String get accountIntroAnonymous;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String accountSignedInAs(String email);

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// No description provided for @accountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get accountPasswordHint;

  /// No description provided for @accountCreate.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountCreate;

  /// No description provided for @accountHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get accountHaveAccount;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// No description provided for @accountForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get accountForgot;

  /// No description provided for @accountResetSent.
  ///
  /// In en, this message translates to:
  /// **'If this email has an account, a link to reset the password is on its way.'**
  String get accountResetSent;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress stays safe in your account and is removed from this phone. Sign in again to get it back.'**
  String get accountSignOutBody;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account and data'**
  String get accountDelete;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This erases your account, your cloud save and your progress on this phone. It cannot be undone.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeletePassword.
  ///
  /// In en, this message translates to:
  /// **'Password to confirm'**
  String get accountDeletePassword;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get accountDeleted;

  /// No description provided for @pointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore points'**
  String get pointsTitle;

  /// No description provided for @pointsIntro.
  ///
  /// In en, this message translates to:
  /// **'Copies kept in your account. They are made at milestones, once a day, and before a reset or a restore.'**
  String get pointsIntro;

  /// No description provided for @pointsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No restore points yet.'**
  String get pointsEmpty;

  /// No description provided for @pointDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily copy'**
  String get pointDaily;

  /// No description provided for @pointReplaced.
  ///
  /// In en, this message translates to:
  /// **'Before a restore'**
  String get pointReplaced;

  /// No description provided for @pointReset.
  ///
  /// In en, this message translates to:
  /// **'Before a reset'**
  String get pointReset;

  /// No description provided for @pointSummary.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP, {lessons} lessons, {streak} day streak'**
  String pointSummary(int xp, int lessons, int streak);

  /// No description provided for @pointRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get pointRestore;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this copy?'**
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

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Which progress do you want to keep?'**
  String get conflictTitle;

  /// No description provided for @conflictBody.
  ///
  /// In en, this message translates to:
  /// **'This phone and your account hold different progress. The one you do not choose is kept as a restore point.'**
  String get conflictBody;

  /// No description provided for @conflictPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get conflictPhone;

  /// No description provided for @conflictAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get conflictAccount;

  /// No description provided for @conflictUseAccount.
  ///
  /// In en, this message translates to:
  /// **'Use the account progress'**
  String get conflictUseAccount;

  /// No description provided for @conflictUsePhone.
  ///
  /// In en, this message translates to:
  /// **'Keep this phone progress'**
  String get conflictUsePhone;

  /// No description provided for @conflictLater.
  ///
  /// In en, this message translates to:
  /// **'Decide later'**
  String get conflictLater;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInNoProgress.
  ///
  /// In en, this message translates to:
  /// **'This account has no saved progress yet. Finish setting up and it will be saved here.'**
  String get signInNoProgress;

  /// No description provided for @onboardingHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get onboardingHaveAccount;

  /// No description provided for @accountHint.
  ///
  /// In en, this message translates to:
  /// **'{milestone}! Create an account so you never lose your progress. Tap here.'**
  String accountHint(String milestone);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address does not look right.'**
  String get errorInvalidEmail;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use a password with at least 8 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Use Sign in instead.'**
  String get errorEmailInUse;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or the password is wrong.'**
  String get errorWrongCredentials;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Please try again when you are online.'**
  String get errorNetwork;

  /// No description provided for @errorTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Please wait a few minutes.'**
  String get errorTooMany;

  /// No description provided for @errorDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been turned off.'**
  String get errorDisabled;

  /// No description provided for @errorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is not turned on for this app.'**
  String get errorNotAllowed;

  /// No description provided for @errorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again and then retry.'**
  String get errorRecentLogin;

  /// No description provided for @errorUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Your latest progress is not in the cloud yet. Connect to the internet and try again.'**
  String get errorUnsaved;

  /// No description provided for @errorTooNew.
  ///
  /// In en, this message translates to:
  /// **'This save was made by a newer version of the app. Please update the app first.'**
  String get errorTooNew;

  /// No description provided for @errorDamaged.
  ///
  /// In en, this message translates to:
  /// **'This save is damaged. It was not restored.'**
  String get errorDamaged;

  /// No description provided for @errorNoCourse.
  ///
  /// In en, this message translates to:
  /// **'This save has no progress for this course.'**
  String get errorNoCourse;

  /// No description provided for @errorTooBig.
  ///
  /// In en, this message translates to:
  /// **'Your progress is too large to save to the cloud.'**
  String get errorTooBig;

  /// No description provided for @errorRefused.
  ///
  /// In en, this message translates to:
  /// **'The cloud did not accept the request. Please try again later.'**
  String get errorRefused;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Nothing was changed.'**
  String get errorGeneric;

  /// No description provided for @resetNeedsOnline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to reset, so your progress can be restored if you change your mind.'**
  String get resetNeedsOnline;
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
