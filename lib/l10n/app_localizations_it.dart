// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get accountTitle => 'Account e salvataggio nel cloud';

  @override
  String get accountTileSubtitle => 'Metti al sicuro i tuoi progressi';

  @override
  String get cloudUnavailable =>
      'Il salvataggio nel cloud non è disponibile in questa versione. I tuoi progressi restano su questo telefono.';

  @override
  String get cloudSignedOut => 'Non ancora salvato nel cloud.';

  @override
  String get cloudSyncing => 'Salvataggio...';

  @override
  String cloudSaved(String when) {
    return 'Salvato nel cloud $when';
  }

  @override
  String get cloudPending => 'Le modifiche saranno salvate a breve.';

  @override
  String get cloudOffline =>
      'Nessuna connessione. I tuoi progressi sono al sicuro su questo telefono e saranno salvati quando sarai online.';

  @override
  String get cloudError =>
      'Impossibile salvare nel cloud. Tocca Salva ora per riprovare.';

  @override
  String get cloudConflict =>
      'Questo telefono e il tuo account hanno progressi diversi. Scegli quali tenere.';

  @override
  String get cloudSaveNow => 'Salva ora';

  @override
  String get cloudChoose => 'Scegli';

  @override
  String get accountIntroAnonymous =>
      'I tuoi progressi vengono salvati nel cloud da soli. Aggiungi un\'email e una password per ritrovarli su un nuovo telefono o dopo aver reinstallato l\'app.';

  @override
  String accountSignedInAs(String email) {
    return 'Accesso come $email';
  }

  @override
  String get accountEmail => 'Email';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordHint => 'Almeno 8 caratteri';

  @override
  String get accountCreate => 'Crea account';

  @override
  String get accountHaveAccount => 'Ho già un account';

  @override
  String get accountSignIn => 'Accedi';

  @override
  String get accountForgot => 'Password dimenticata?';

  @override
  String get accountResetSent =>
      'Se questa email ha un account, ti sta arrivando un link per reimpostare la password.';

  @override
  String get accountSignOut => 'Esci';

  @override
  String get accountSignOutBody =>
      'I tuoi progressi restano al sicuro nel tuo account e vengono rimossi da questo telefono. Accedi di nuovo per riaverli.';

  @override
  String get accountDelete => 'Elimina account e dati';

  @override
  String get accountDeleteBody =>
      'Questo cancella il tuo account, il salvataggio nel cloud e i progressi su questo telefono. Non si può annullare.';

  @override
  String get accountDeletePassword => 'Password per confermare';

  @override
  String get accountDeleted => 'Account eliminato.';

  @override
  String get pointsTitle => 'Punti di ripristino';

  @override
  String get pointsIntro =>
      'Copie conservate nel tuo account. Vengono create ai traguardi, una volta al giorno e prima di un azzeramento o di un ripristino.';

  @override
  String get pointsEmpty => 'Nessun punto di ripristino.';

  @override
  String get pointDaily => 'Copia giornaliera';

  @override
  String get pointReplaced => 'Prima di un ripristino';

  @override
  String get pointReset => 'Prima di un azzeramento';

  @override
  String pointSummary(int xp, int lessons, int streak) {
    return '$xp XP, $lessons lezioni, serie di $streak giorni';
  }

  @override
  String get pointRestore => 'Ripristina';

  @override
  String get restoreConfirmTitle => 'Ripristinare questa copia?';

  @override
  String restoreConfirmBody(String date, int xp, int lessons, int streak) {
    return 'Salvata il $date\n$xp XP, $lessons lezioni, serie di $streak giorni.\n\nI tuoi progressi attuali verranno sostituiti. Prima ne salviamo un punto di ripristino, così puoi annullare.';
  }

  @override
  String get restoreConfirmAction => 'Ripristina';

  @override
  String get restoreDone => 'Progressi ripristinati.';

  @override
  String get conflictTitle => 'Quali progressi vuoi tenere?';

  @override
  String get conflictBody =>
      'Questo telefono e il tuo account hanno progressi diversi. Quelli che non scegli vengono conservati come punto di ripristino.';

  @override
  String get conflictPhone => 'Questo telefono';

  @override
  String get conflictAccount => 'Il tuo account';

  @override
  String get conflictUseAccount => 'Usa i progressi dell\'account';

  @override
  String get conflictUsePhone => 'Tieni i progressi del telefono';

  @override
  String get conflictLater => 'Decidi dopo';

  @override
  String get signInTitle => 'Accedi';

  @override
  String get signInNoProgress =>
      'Questo account non ha ancora progressi salvati. Finisci la configurazione e verranno salvati qui.';

  @override
  String get onboardingHaveAccount => 'Ho già un account';

  @override
  String accountHint(String milestone) {
    return '$milestone! Crea un account per non perdere mai i tuoi progressi. Tocca qui.';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get errorInvalidEmail => 'Questo indirizzo email non sembra corretto.';

  @override
  String get errorWeakPassword => 'Usa una password di almeno 8 caratteri.';

  @override
  String get errorEmailInUse => 'Questa email ha già un account. Usa Accedi.';

  @override
  String get errorWrongCredentials => 'L\'email o la password sono sbagliate.';

  @override
  String get errorNetwork => 'Nessuna connessione. Riprova quando sei online.';

  @override
  String get errorTooMany => 'Troppi tentativi. Aspetta qualche minuto.';

  @override
  String get errorDisabled => 'Questo account è stato disattivato.';

  @override
  String get errorNotAllowed =>
      'L\'accesso con email non è attivo per questa app.';

  @override
  String get errorRecentLogin => 'Accedi di nuovo e poi riprova.';

  @override
  String get errorUnsaved =>
      'I tuoi ultimi progressi non sono ancora nel cloud. Collegati a internet e riprova.';

  @override
  String get errorTooNew =>
      'Questo salvataggio è stato creato da una versione più recente dell\'app. Aggiorna prima l\'app.';

  @override
  String get errorDamaged =>
      'Questo salvataggio è danneggiato. Non è stato ripristinato.';

  @override
  String get errorNoCourse =>
      'Questo salvataggio non contiene progressi per questo corso.';

  @override
  String get errorTooBig =>
      'I tuoi progressi sono troppo grandi per essere salvati nel cloud.';

  @override
  String get errorRefused =>
      'Il cloud non ha accettato la richiesta. Riprova più tardi.';

  @override
  String get errorGeneric =>
      'Qualcosa è andato storto. Non è stato modificato nulla.';

  @override
  String get resetNeedsOnline =>
      'Collegati a internet per azzerare, così i tuoi progressi si potranno ripristinare se cambi idea.';
}
