// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get backupTitle => 'Copia de seguridad y restauración';

  @override
  String get backupSettingsTile => 'Copia de seguridad y restauración';

  @override
  String get backupSettingsTileSubtitle => 'Mantén tu progreso a salvo';

  @override
  String get backupIntro =>
      'Tu progreso solo está en este teléfono. Si desinstalas la app, se borra. Guarda el archivo de copia en un lugar seguro, como Archivos o Drive.';

  @override
  String get backupFileCard => 'Archivo de copia';

  @override
  String backupFileName(String name) {
    return 'Nombre del archivo: $name';
  }

  @override
  String get backupFileHint =>
      'Solo hay un archivo. Al guardar de nuevo, se reemplaza el anterior.';

  @override
  String get backupSaveButton => 'Guardar archivo de copia';

  @override
  String get backupShareButton => 'Compartir archivo de copia';

  @override
  String get backupImportButton => 'Restaurar desde un archivo';

  @override
  String get backupSaved => 'Copia guardada.';

  @override
  String get backupSharedReady =>
      'El archivo de copia está listo para compartir.';

  @override
  String get backupSaveFailed =>
      'No se pudo guardar la copia. Inténtalo de nuevo.';

  @override
  String get checkpointsTitle => 'Puntos de restauración';

  @override
  String get checkpointsIntro =>
      'Instantáneas rápidas guardadas dentro de la app. Se eliminan si desinstalas.';

  @override
  String get checkpointsEmpty => 'Aún no hay puntos de restauración.';

  @override
  String get checkpointCreate => 'Crear un punto de restauración';

  @override
  String get checkpointLabelField => 'Nombre (opcional)';

  @override
  String get checkpointAuto => 'Automático';

  @override
  String checkpointSummary(int xp, int lessons, int streak) {
    return '$xp XP, $lessons lecciones, racha de $streak días';
  }

  @override
  String get checkpointCreated => 'Punto de restauración creado.';

  @override
  String get checkpointDeleted => 'Punto de restauración eliminado.';

  @override
  String get checkpointRename => 'Cambiar nombre';

  @override
  String get checkpointDelete => 'Eliminar';

  @override
  String get checkpointRestore => 'Restaurar';

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
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get onboardingHaveBackup => 'Ya tengo una copia';

  @override
  String get errorUnreadable =>
      'No se puede leer este archivo. Elige un archivo de copia de Multilingo.';

  @override
  String get errorNotMultilingo =>
      'Este no es un archivo de copia de Multilingo.';

  @override
  String get errorTooNew =>
      'Esta copia fue creada por una versión más nueva de la app. Actualiza la app primero.';

  @override
  String get errorDamaged =>
      'Esta copia está dañada o fue modificada. No se restauró.';

  @override
  String get errorNoCourse => 'Esta copia no tiene progreso para este curso.';

  @override
  String get errorGeneric => 'Algo salió mal. No se cambió nada.';
}
