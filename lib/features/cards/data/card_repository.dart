import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/srs/sm2_scheduler.dart';

/// id deck "gabungan" untuk semua kartu berbintang.
const kFavoritesDeckId = -1;

class CardRepository {
  CardRepository(this._db);
  final AppDatabase _db;

  Expression<bool> _inDeck($CardsTable c, int deckId) =>
      deckId == kFavoritesDeckId
          ? c.isFavorite.equals(true)
          : c.deckId.equals(deckId);

  Stream<List<FlashCard>> watchCards(int deckId) {
    return (_db.select(_db.cards)
          ..where((c) => _inDeck(c, deckId))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .watch();
  }

  Stream<List<FlashCard>> watchAllCards() => _db.select(_db.cards).watch();

  /// Waktu review terakhir tiap kartu (cardId -> waktu).
  Stream<Map<int, DateTime>> watchLastReviews() {
    return _db.select(_db.reviewLogs).watch().map((rows) {
      final m = <int, DateTime>{};
      for (final r in rows) {
        final cur = m[r.cardId];
        if (cur == null || r.reviewedAt.isAfter(cur)) m[r.cardId] = r.reviewedAt;
      }
      return m;
    });
  }

  Future<int> addCard(int deckId, String front, String back) {
    return _db.into(_db.cards).insert(
          CardsCompanion.insert(deckId: deckId, front: front, back: back),
        );
  }

  Future<void> updateCard(int id, String front, String back) {
    return (_db.update(_db.cards)..where((c) => c.id.equals(id))).write(
      CardsCompanion(
        front: Value(front),
        back: Value(back),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setFavorite(int id, bool value) {
    return (_db.update(_db.cards)..where((c) => c.id.equals(id)))
        .write(CardsCompanion(isFavorite: Value(value)));
  }

  Future<void> deleteCard(int id) {
    return (_db.delete(_db.cards)..where((c) => c.id.equals(id))).go();
  }

  /// Kartu yang jatuh tempo hari ini atau sebelumnya.
  Future<List<FlashCard>> getDueCards(int deckId) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    return (_db.select(_db.cards)
          ..where((c) =>
              _inDeck(c, deckId) & c.dueDate.isSmallerThanValue(endOfToday))
          ..orderBy([(c) => OrderingTerm.asc(c.dueDate)]))
        .get();
  }

  Stream<int> watchDueCount(int deckId) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    final count = _db.cards.id.count();
    final query = _db.selectOnly(_db.cards)
      ..addColumns([count])
      ..where(_inDeck(_db.cards, deckId) &
          _db.cards.dueDate.isSmallerThanValue(endOfToday));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Simpan hasil penilaian: jadwal baru + catatan review, dalam satu transaksi.
  Future<void> reviewCard(FlashCard card, Rating rating) {
    return _db.transaction(() async {
      final next = Sm2Scheduler.review(card.srs, rating);
      await (_db.update(_db.cards)..where((c) => c.id.equals(card.id))).write(
        CardsCompanion(
          repetitions: Value(next.repetitions),
          easeFactor: Value(next.easeFactor),
          intervalDays: Value(next.intervalDays),
          dueDate: Value(next.dueDate),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _db.into(_db.reviewLogs).insert(
            ReviewLogsCompanion.insert(cardId: card.id, rating: rating.index),
          );
    });
  }
}

extension FlashCardSrs on FlashCard {
  SrsState get srs => SrsState(
        repetitions: repetitions,
        easeFactor: easeFactor,
        intervalDays: intervalDays,
        dueDate: dueDate,
      );
}