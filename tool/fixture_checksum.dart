// Helpers used once to write the frozen files in test/fixtures/backups/.
// Never regenerate a fixture after release: old files must keep decoding
// exactly as they are. To freeze a new schema, run this once, save the output
// as a new fixture, then add the expectations in test/backup_compat_test.dart.
//
//   dart run tool/fixture_checksum.dart v2 <file>   prints the schema 2 checksum
//   dart run tool/fixture_checksum.dart v3 <file>   prints a schema 3 file built
//                                                   from a schema 1 fixture
import 'dart:convert';
import 'dart:io';

import 'package:multilingo/domain/backup.dart';

void main(List<String> args) {
  final json = jsonDecode(File(args[1]).readAsStringSync()) as Map<String, dynamic>;
  if (args.first == 'v2') {
    final courses = {
      for (final e in (json['courses'] as Map<String, dynamic>).entries)
        e.key: e.value as Map<String, dynamic>,
    };
    stdout.writeln(checksumOf(courses));
  } else {
    stdout.writeln(BackupEnvelope.fromStates(
      id: '1780000000000000',
      createdAt: DateTime.utc(2026, 6, 1, 9),
      label: 'Phone',
      kind: BackupKind.manual,
      appVersion: '0.2.0',
      states: {'it': json, 'es': {'completedLessons': ['es1']}},
    ).encode());
  }
}
