import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class DeckRepository {
  DeckRepository(this._db);
  final AppDatabase _db;

  Stream<List<Deck>> watchDecks() {
    return (_db.select(_db.decks)
          ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .watch();
  }

   Future<int> addDeck(String name, String description,
      {String kind = 'vocab'}) {
    return _db.into(_db.decks).insert(
          DecksCompanion.insert(
            name: name,
            description: Value(description),
            kind: Value(kind),  
          ),
        );
  }

  Future<void> updateDeck(int id, String name, String description) {
    return (_db.update(_db.decks)..where((d) => d.id.equals(id))).write(
      DecksCompanion(name: Value(name), description: Value(description)),
    );
  }

  Future<void> deleteDeck(int id) {
    return (_db.delete(_db.decks)..where((d) => d.id.equals(id))).go();
  }
}