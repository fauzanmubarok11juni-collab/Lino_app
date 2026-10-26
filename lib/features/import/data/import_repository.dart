import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import 'import_parser.dart';

class ImportResult {
  const ImportResult(this.newDecks, this.added, this.updated, this.unchanged);
  final int newDecks;
  final int added;
  final int updated;
  final int unchanged;
}

class ImportRepository {
  ImportRepository(this._db);
  final AppDatabase _db;

  Future<ImportResult> save(List<ParsedSection> sections,
      {required bool reverseVocab}) {
    return _db.transaction(() async {
      var newDecks = 0, added = 0, updated = 0, unchanged = 0;

      for (final s in sections) {
        final valid = s.cards.where((c) => c.isValid).toList();
        if (valid.isEmpty) continue;

        final found = await (_db.select(_db.decks)
              ..where((d) => d.name.equals(s.name) & d.kind.equals(s.deckKind)))
            .get();
        final int deckId;
        if (found.isEmpty) {
          deckId = await _db.into(_db.decks).insert(DecksCompanion.insert(
                name: s.name,
                kind: Value(s.deckKind),
              ));
          newDecks++;
        } else {
          deckId = found.first.id;
        }

        final existing = await (_db.select(_db.cards)
              ..where((c) => c.deckId.equals(deckId)))
            .get();
        final byFront = {for (final c in existing) c.front: c};
        final seenNew = <String>{};
        final toInsert = <CardsCompanion>[];

        Future<void> upsert(String type, String front, String answer,
            String explanation, List<String> choices) async {
          final back = explanation.isEmpty ? answer : '$answer\n$explanation';
          final choicesJson = jsonEncode(choices);
          final old = byFront[front];

          if (old != null) {
            final same = old.questionType == type &&
                old.answer == answer &&
                old.explanation == explanation &&
                old.choices == choicesJson &&
                old.back == back;
            if (same) {
              unchanged++;
              return;
            }
            await (_db.update(_db.cards)..where((c) => c.id.equals(old.id)))
                .write(CardsCompanion(
              questionType: Value(type),
              answer: Value(answer),
              explanation: Value(explanation),
              choices: Value(choicesJson),
              back: Value(back),
              updatedAt: Value(DateTime.now()),
            ));
            updated++;
            return;
          }

          if (!seenNew.add(front)) {
            unchanged++; // duplikat di dalam file yang sama
            return;
          }
          toInsert.add(CardsCompanion.insert(
            deckId: deckId,
            front: front,
            back: back,
            questionType: Value(type),
            answer: Value(answer),
            explanation: Value(explanation),
            choices: Value(choicesJson),
          ));
          added++;
        }

        for (final c in valid) {
          await upsert(c.type, c.front.trim(), c.answer.trim(),
              c.explanation.trim(), c.choices);
          if (reverseVocab && s.deckKind == 'vocab' && c.type == 'V') {
            await upsert('V', c.answer.trim(), c.front.trim(), '', const []);
          }
        }
        await _db.batch((b) => b.insertAll(_db.cards, toInsert));
      }
      return ImportResult(newDecks, added, updated, unchanged);
    });
  }
}