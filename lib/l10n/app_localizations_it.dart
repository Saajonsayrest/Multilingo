// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get backupTitle => 'Backup e ripristino';

  @override
  String get backupSettingsTile => 'Backup e ripristino';

  @override
  String get backupSettingsTileSubtitle => 'Metti al sicuro i tuoi progressi';

  @override
  String get backupIntro =>
      'I tuoi progressi sono salvati solo su questo telefono. Se disinstalli l\'app, vengono cancellati. Salva il file di backup in un posto sicuro, come File o Drive.';

  @override
  String get backupFileCard => 'File di backup';

  @override
  String backupFileName(String name) {
    return 'Nome del file: $name';
  }

  @override
  String get backupFileHint =>
      'C\'è un solo file. Salvando di nuovo, quello vecchio viene sostituito.';

  @override
  String get backupSaveButton => 'Salva il file di backup';

  @override
  String get backupShareButton => 'Condividi il file di backup';

  @override
  String get backupImportButton => 'Ripristina da un file';

  @override
  String get backupSaved => 'Backup salvato.';

  @override
  String get backupSharedReady => 'Il file di backup è pronto da condividere.';

  @override
  String get backupSaveFailed => 'Impossibile salvare il backup. Riprova.';

  @override
  String get checkpointsTitle => 'Punti di ripristino';

  @override
  String get checkpointsIntro =>
      'Istantanee veloci conservate nell\'app. Vengono rimosse se disinstalli.';

  @override
  String get checkpointsEmpty => 'Nessun punto di ripristino.';

  @override
  String get checkpointCreate => 'Crea un punto di ripristino';

  @override
  String get checkpointLabelField => 'Nome (facoltativo)';

  @override
  String get checkpointAuto => 'Automatico';

  @override
  String checkpointSummary(int xp, int lessons, int streak) {
    return '$xp XP, $lessons lezioni, serie di $streak giorni';
  }

  @override
  String get checkpointCreated => 'Punto di ripristino creato.';

  @override
  String get checkpointDeleted => 'Punto di ripristino eliminato.';

  @override
  String get checkpointRename => 'Rinomina';

  @override
  String get checkpointDelete => 'Elimina';

  @override
  String get checkpointRestore => 'Ripristina';

  @override
  String get restoreConfirmTitle => 'Ripristinare questo backup?';

  @override
  String restoreConfirmBody(String date, int xp, int lessons, int streak) {
    return 'Salvato il $date\n$xp XP, $lessons lezioni, serie di $streak giorni.\n\nI tuoi progressi attuali verranno sostituiti. Prima ne salviamo un punto di ripristino, così puoi annullare.';
  }

  @override
  String get restoreConfirmAction => 'Ripristina';

  @override
  String get restoreDone => 'Progressi ripristinati.';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get onboardingHaveBackup => 'Ho già un backup';

  @override
  String get errorUnreadable =>
      'Questo file non può essere letto. Scegli un file di backup di Multilingo.';

  @override
  String get errorNotMultilingo =>
      'Questo non è un file di backup di Multilingo.';

  @override
  String get errorTooNew =>
      'Questo backup è stato creato da una versione più recente dell\'app. Aggiorna prima l\'app.';

  @override
  String get errorDamaged =>
      'Questo backup è danneggiato o è stato modificato. Non è stato ripristinato.';

  @override
  String get errorNoCourse =>
      'Questo backup non contiene progressi per questo corso.';

  @override
  String get errorGeneric =>
      'Qualcosa è andato storto. Non è stato modificato nulla.';
}
