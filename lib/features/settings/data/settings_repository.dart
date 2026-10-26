import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Stream<Map<String, String>> watchAll() =>
      _db.select(_db.appSettings).watch().map(
            (rows) => {for (final r in rows) r.key: r.value},
          );

  Future<void> set(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<void> setMany(Map<String, String> entries) {
    return _db.transaction(() async {
      for (final e in entries.entries) {
        await _db.into(_db.appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(key: e.key, value: e.value),
            );
      }
    });
  }
}