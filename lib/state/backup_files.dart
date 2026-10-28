import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/backup.dart';

/// Talks to the phone's file dialogs. An interface so tests can replace it.
abstract class BackupFiles {
  /// Opens "save as" with the fixed file name. Returns false if cancelled.
  Future<bool> saveAs(Uint8List bytes);

  /// Opens the system share sheet with [file].
  Future<void> share(File file, {Rect? origin});

  /// Lets the user choose a .json file. Null if cancelled.
  Future<String?> pickText();
}

class SystemBackupFiles implements BackupFiles {
  const SystemBackupFiles();

  @override
  Future<bool> saveAs(Uint8List bytes) async {
    final uri = await FilePicker.saveFile(
      fileName: backupFileName,
      bytes: bytes,
      mimeType: 'application/json',
    );
    return uri != null;
  }

  @override
  Future<void> share(File file, {Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, name: backupFileName, mimeType: 'application/json')],
        fileNameOverrides: const [backupFileName],
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Future<String?> pickText() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    // Reject huge files early: a real backup is a few kilobytes.
    if (bytes.length > 5 * 1024 * 1024) {
      throw const BackupException(BackupError.notMultilingo);
    }
    if (bytes.isEmpty) throw const BackupException(BackupError.unreadable);
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const BackupException(BackupError.unreadable);
    }
  }
}

final backupFilesProvider =
    Provider<BackupFiles>((ref) => const SystemBackupFiles());
