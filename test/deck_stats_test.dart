import 'package:flashcard_app/core/database/app_database.dart';
import 'package:flashcard_app/features/decks/providers/deck_stats_providers.dart';
import 'package:flutter_test/flutter_test.dart';

FlashCard c(int id, {int interval = 0, DateTime? due, bool fav = false}) =>
    FlashCard(
      id: id,
      deckId: 1,
      front: 'f$id',
      back: 'b',
      questionType: 'basic',
      answer: '',
      choices: '',
      explanation: '',
      isFavorite: fav,
      repetitions: 0,
      easeFactor: 2.5,
      intervalDays: interval,
      dueDate: due ?? DateTime(2026, 10, 1),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

final deck = Deck(
    id: 1, name: 'D', description: '', kind: 'vocab', createdAt: DateTime(2026));
final now = DateTime(2026, 10, 20, 15);

void main() {
  test('kartu matang = interval 21 hari atau lebih', () {
    final s = computeDeckStats(
        deck, [c(1, interval: 21), c(2, interval: 20), c(3), c(4)], {},
        now: now);
    expect(s.mature, 1);
    expect(s.progress, 0.25);
    expect(s.mastered, isFalse);
  });

  test('deck dikuasai di 80%', () {
    final cards = [for (var i = 0; i < 4; i++) c(i, interval: 30), c(9)];
    final s = computeDeckStats(deck, cards, {}, now: now);
    expect(s.progress, 0.8);
    expect(s.mastered, isTrue);
  });

  test('jatuh tempo: hari ini termasuk, besok tidak', () {
    final s = computeDeckStats(
        deck,
        [
          c(1, due: DateTime(2026, 10, 20, 23)),
          c(2, due: DateTime(2026, 10, 21)),
        ],
        {},
        now: now);
    expect(s.due, 1);
  });

  test('sedang dipelajari dan terakhir belajar', () {
    final s = computeDeckStats(deck, [c(1), c(2)],
        {1: DateTime(2026, 10, 18), 2: DateTime(2026, 10, 19)},
        now: now);
    expect(s.studied, isTrue);
    expect(s.learning, isTrue);
    expect(s.lastStudied, DateTime(2026, 10, 19));
    expect(computeDeckStats(deck, [c(1)], {}, now: now).learning, isFalse);
  });

  test('favorit dihitung', () {
    final s = computeDeckStats(deck, [c(1, fav: true), c(2)], {}, now: now);
    expect(s.favorites, 1);
  });
}