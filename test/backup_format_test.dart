import 'package:flashcard_app/features/backup/data/backup_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tables = {
    'decks': [
      {'id': 1, 'name': 'Things & People', 'kind': 'vocab'}
    ],
    'cards': [
      {'id': 1, 'deck_id': 1, 'front': 'book', 'ease_factor': 2.5},
      {'id': 2, 'deck_id': 1, 'front': 'pen', 'ease_factor': 2.36},
    ],
    'review_logs': <Map<String, Object?>>[],
  };

  test('encode lalu decode menghasilkan data yang sama', () {
    final text = encodeBackup(
        schemaVersion: 4, now: DateTime(2026, 10, 26, 8, 30), tables: tables);
    final info = decodeBackup(text, currentSchemaVersion: 4);
    expect(info.schemaVersion, 4);
    expect(info.exportedAt, DateTime(2026, 10, 26, 8, 30));
    expect(info.countOf('decks'), 1);
    expect(info.countOf('cards'), 2);
    expect(info.countOf('review_logs'), 0);
    expect(info.countOf('tidak_ada'), 0);
    expect(info.tables['cards']![1]['ease_factor'], 2.36);
    expect(info.tables['decks']![0]['name'], 'Things & People');
  });

  test('menolak file yang bukan backup', () {
    expect(() => decodeBackup('bukan json', currentSchemaVersion: 4),
        throwsA(isA<BackupException>()));
    expect(() => decodeBackup('{"a": 1}', currentSchemaVersion: 4),
        throwsA(isA<BackupException>()));
    expect(() => decodeBackup('[1, 2]', currentSchemaVersion: 4),
        throwsA(isA<BackupException>()));
  });

  test('menolak backup dari versi aplikasi yang lebih baru', () {
    final text = encodeBackup(schemaVersion: 9, now: DateTime(2026), tables: {});
    expect(() => decodeBackup(text, currentSchemaVersion: 4),
        throwsA(isA<BackupException>()));
  });

  test('menerima backup versi lama dan file dengan BOM', () {
    final text = encodeBackup(schemaVersion: 2, now: DateTime(2026), tables: tables);
    final info = decodeBackup('\uFEFF$text', currentSchemaVersion: 4);
    expect(info.schemaVersion, 2);
  });

  test('menolak baris tabel yang rusak', () {
    const bad =
        '{"app":"lingoflip","schemaVersion":4,"tables":{"cards":[1,2]}}';
    expect(() => decodeBackup(bad, currentSchemaVersion: 4),
        throwsA(isA<BackupException>()));
  });
}
