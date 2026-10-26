import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import 'backup_format.dart';

class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  int get schemaVersion => _db.schemaVersion;

  /// Membaca semua tabel apa adanya (nilai mentah SQLite).
  Future<String> export() async {
    final tables = <String, List<Map<String, Object?>>>{};
    for (final t in _db.allTables) {
      final name = t.actualTableName;
      final rows = await _db.customSelect('SELECT * FROM "$name"').get();
      tables[name] = [for (final r in rows) Map<String, Object?>.of(r.data)];
    }
    return encodeBackup(
      schemaVersion: _db.schemaVersion,
      now: DateTime.now(),
      tables: tables,
    );
  }

  /// Mengganti seluruh isi database dengan isi backup, dalam satu transaksi.
  /// Kalau ada kegagalan, semua perubahan dibatalkan.
      Future<void> restore(BackupInfo info) async {
    final tables = _db.allTables.toList(); // induk dulu, lalu anak
    await _db.transaction(() async {
      for (final t in tables.reversed) {
        final name = t.actualTableName;
        if (!info.tables.containsKey(name)) continue; // tabel baru: biarkan
        await _db.customStatement('DELETE FROM "$name"');
      }
      for (final t in tables) {
        final name = t.actualTableName;
        final known = {for (final c in t.$columns) c.name};
        for (final row in info.tables[name] ?? const <Map<String, Object?>>[]) {
          final cols = row.keys.where(known.contains).toList();
          if (cols.isEmpty) continue;
          final sql = 'INSERT INTO "$name" '
              '(${cols.map((c) => '"$c"').join(',')}) '
              'VALUES (${List.filled(cols.length, '?').join(',')})';
          await _db.customStatement(sql, [for (final c in cols) row[c]]);
        }
      }
    });
    _db.markTablesUpdated(tables);
  }
}