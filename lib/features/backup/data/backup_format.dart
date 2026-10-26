import 'dart:convert';

const kBackupApp = 'lingoflip';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BackupInfo {
  BackupInfo({
    required this.schemaVersion,
    required this.exportedAt,
    required this.tables,
  });

  final int schemaVersion;
  final DateTime? exportedAt;
  final Map<String, List<Map<String, Object?>>> tables;

  int countOf(String table) => tables[table]?.length ?? 0;
}

String encodeBackup({
  required int schemaVersion,
  required DateTime now,
  required Map<String, List<Map<String, Object?>>> tables,
}) {
  return jsonEncode({
    'app': kBackupApp,
    'schemaVersion': schemaVersion,
    'exportedAt': now.toIso8601String(),
    'tables': tables,
  });
}

BackupInfo decodeBackup(String text, {required int currentSchemaVersion}) {
  final Object? raw;
  try {
    raw = jsonDecode(text.replaceFirst('\uFEFF', ''));
  } on FormatException {
    throw BackupException('File ini bukan backup yang valid.');
  }
  if (raw is! Map || raw['app'] != kBackupApp) {
    throw BackupException('File ini bukan backup LingoFlip.');
  }

  final version = raw['schemaVersion'];
  if (version is! int || version < 1) {
    throw BackupException('Versi backup tidak dikenali.');
  }
  if (version > currentSchemaVersion) {
    throw BackupException(
        'Backup ini dibuat oleh versi aplikasi yang lebih baru. Perbarui aplikasi lebih dulu.');
  }

  final rawTables = raw['tables'];
  if (rawTables is! Map) {
    throw BackupException('Isi backup rusak.');
  }

  final tables = <String, List<Map<String, Object?>>>{};
  for (final entry in rawTables.entries) {
    final rows = entry.value;
    if (entry.key is! String || rows is! List) {
      throw BackupException('Isi backup rusak pada tabel ${entry.key}.');
    }
    final list = <Map<String, Object?>>[];
    for (final r in rows) {
      if (r is! Map) {
        throw BackupException('Isi backup rusak pada tabel ${entry.key}.');
      }
      list.add(Map<String, Object?>.from(r));
    }
    tables[entry.key as String] = list;
  }

  final at = raw['exportedAt'];
  return BackupInfo(
    schemaVersion: version,
    exportedAt: at is String ? DateTime.tryParse(at) : null,
    tables: tables,
  );
}