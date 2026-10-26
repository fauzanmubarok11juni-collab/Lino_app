import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../cards/data/card_repository.dart' show kFavoritesDeckId;

class PracticeRepository {
  PracticeRepository(this._db);
  final AppDatabase _db;

  Future<List<FlashCard>> getDeckCards(int deckId) => (_db.select(_db.cards)
        ..where((c) => deckId == kFavoritesDeckId
            ? c.isFavorite.equals(true)
            : c.deckId.equals(deckId)))
      .get();

  Future<void> log(int cardId, bool correct) => _db
      .into(_db.practiceLogs)
      .insert(PracticeLogsCompanion.insert(cardId: cardId, correct: correct));
}