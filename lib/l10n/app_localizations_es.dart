// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get accountTitle => 'Cuenta y guardado en la nube';

  @override
  String get accountTileSubtitle => 'Mantén tu progreso a salvo';

  @override
  String get cloudUnavailable =>
      'El guardado en la nube no está disponible en esta versión. Tu progreso se queda en este teléfono.';

  @override
  String get cloudSignedOut => 'Aún no se ha guardado en la nube.';

  @override
  String get cloudSyncing => 'Guardando...';

  @override
  String cloudSaved(String when) {
    return 'Guardado en la nube $when';
  }

  @override
  String get cloudPending => 'Los cambios se guardarán en un momento.';

  @override
  String get cloudOffline =>
      'Sin conexión. Tu progreso está a salvo en este teléfono y se guardará cuando estés en línea.';

  @override
  String get cloudError =>
      'No se pudo guardar en la nube. Toca Guardar ahora para intentarlo de nuevo.';

  @override
  String get cloudConflict =>
      'Este teléfono y tu cuenta tienen progreso distinto. Elige cuál conservar.';

  @override
  String get cloudSaveNow => 'Guardar ahora';

  @override
  String get cloudChoose => 'Elegir';

  @override
  String get accountIntroAnonymous =>
      'Tu progreso se guarda solo en la nube. Añade un correo y una contraseña para recuperarlo en un teléfono nuevo o después de reinstalar la app.';

  @override
  String accountSignedInAs(String email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String get accountEmail => 'Correo';

  @override
  String get accountPassword => 'Contraseña';

  @override
  String get accountPasswordHint => 'Al menos 8 caracteres';

  @override
  String get accountCreate => 'Crear cuenta';

  @override
  String get accountHaveAccount => 'Ya tengo una cuenta';

  @override
  String get accountSignIn => 'Iniciar sesión';

  @override
  String get accountForgot => '¿Olvidaste la contraseña?';

  @override
  String get accountResetSent =>
      'Si este correo tiene una cuenta, va en camino un enlace para restablecer la contraseña.';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountSignOutBody =>
      'Tu progreso queda a salvo en tu cuenta y se quita de este teléfono. Inicia sesión de nuevo para recuperarlo.';

  @override
  String get accountDelete => 'Eliminar cuenta y datos';

  @override
  String get accountDeleteBody =>
      'Esto borra tu cuenta, tu guardado en la nube y tu progreso en este teléfono. No se puede deshacer.';

  @override
  String get accountDeletePassword => 'Contraseña para confirmar';

  @override
  String get accountDeleted => 'Cuenta eliminada.';

  @override
  String get pointsTitle => 'Puntos de restauración';

  @override
  String get pointsIntro =>
      'Copias guardadas en tu cuenta. Se hacen en los hitos, una vez al día y antes de un reinicio o una restauración.';

  @override
  String get pointsEmpty => 'Aún no hay puntos de restauración.';

  @override
  String get pointDaily => 'Copia diaria';

  @override
  String get pointReplaced => 'Antes de una restauración';

  @override
  String get pointReset => 'Antes de un reinicio';

  @override
  String pointSummary(int xp, int lessons, int streak) {
    return '$xp XP, $lessons lecciones, racha de $streak días';
  }

  @override
  String get pointRestore => 'Restaurar';

  @override
  String get restoreConfirmTitle => '¿Restaurar esta copia?';

  @override
  String restoreConfirmBody(String date, int xp, int lessons, int streak) {
    return 'Guardada el $date\n$xp XP, $lessons lecciones, racha de $streak días.\n\nTu progreso actual será reemplazado. Antes se guarda un punto de restauración, así puedes deshacerlo.';
  }

  @override
  String get restoreConfirmAction => 'Restaurar';

  @override
  String get restoreDone => 'Progreso restaurado.';

  @override
  String get conflictTitle => '¿Qué progreso quieres conservar?';

  @override
  String get conflictBody =>
      'Este teléfono y tu cuenta tienen progreso distinto. El que no elijas se guarda como punto de restauración.';

  @override
  String get conflictPhone => 'Este teléfono';

  @override
  String get conflictAccount => 'Tu cuenta';

  @override
  String get conflictUseAccount => 'Usar el progreso de la cuenta';

  @override
  String get conflictUsePhone => 'Conservar el progreso del teléfono';

  @override
  String get conflictLater => 'Decidir después';

  @override
  String get signInTitle => 'Iniciar sesión';

  @override
  String get signInNoProgress =>
      'Esta cuenta aún no tiene progreso guardado. Termina la configuración y se guardará aquí.';

  @override
  String get onboardingHaveAccount => 'Ya tengo una cuenta';

  @override
  String accountHint(String milestone) {
    return '¡$milestone! Crea una cuenta para no perder nunca tu progreso. Toca aquí.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get errorInvalidEmail => 'Ese correo no parece correcto.';

  @override
  String get errorWeakPassword =>
      'Usa una contraseña de al menos 8 caracteres.';

  @override
  String get errorEmailInUse =>
      'Este correo ya tiene una cuenta. Usa Iniciar sesión.';

  @override
  String get errorWrongCredentials =>
      'El correo o la contraseña no son correctos.';

  @override
  String get errorNetwork =>
      'Sin conexión. Inténtalo de nuevo cuando estés en línea.';

  @override
  String get errorTooMany => 'Demasiados intentos. Espera unos minutos.';

  @override
  String get errorDisabled => 'Esta cuenta ha sido desactivada.';

  @override
  String get errorNotAllowed =>
      'El inicio de sesión con correo no está activado para esta app.';

  @override
  String get errorRecentLogin =>
      'Inicia sesión de nuevo y vuelve a intentarlo.';

  @override
  String get errorUnsaved =>
      'Tu último progreso aún no está en la nube. Conéctate a internet e inténtalo de nuevo.';

  @override
  String get errorTooNew =>
      'Este guardado fue creado por una versión más nueva de la app. Actualiza la app primero.';

  @override
  String get errorDamaged => 'Este guardado está dañado. No se restauró.';

  @override
  String get errorNoCourse =>
      'Este guardado no tiene progreso para este curso.';

  @override
  String get errorTooBig =>
      'Tu progreso es demasiado grande para guardarlo en la nube.';

  @override
  String get errorRefused =>
      'La nube no aceptó la solicitud. Inténtalo más tarde.';

  @override
  String get errorGeneric => 'Algo salió mal. No se cambió nada.';

  @override
  String get resetNeedsOnline =>
      'Conéctate a internet para reiniciar, así tu progreso se podrá restaurar si cambias de opinión.';
}
