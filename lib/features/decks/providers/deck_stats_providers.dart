import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../cards/data/card_repository.dart';
import '../../cards/providers/card_providers.dart';
import 'deck_providers.dart';

const kMatureDays = 21; // kartu dianggap matang
const kMasteredProgress = 0.8; // deck dikuasai

class DeckStats {
  const DeckStats({
    required this.deck,
    required this.total,
    required this.mature,
    required this.due,
    required this.favorites,
    required this.studied,
    this.lastStudied,
  });

  final Deck deck;
  final int total;
  final int mature;
  final int due;
  final int favorites;
  final bool studied; // pernah ada review
  final DateTime? lastStudied;

  double get progress => total == 0 ? 0 : mature / total;
  bool get mastered => total > 0 && progress >= kMasteredProgress;
  bool get learning => studied && !mastered;
}

DeckStats computeDeckStats(
  Deck deck,
  List<FlashCard> cards,
  Map<int, DateTime> lastReviews, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final endOfToday = DateTime(n.year, n.month, n.day + 1);
  DateTime? last;
  var mature = 0, due = 0, fav = 0;
  var studied = false;

  for (final c in cards) {
    if (c.intervalDays >= kMatureDays) mature++;
    if (c.dueDate.isBefore(endOfToday)) due++;
    if (c.isFavorite) fav++;
    final r = lastReviews[c.id];
    if (r != null) {
      studied = true;
      if (last == null || r.isAfter(last)) last = r;
    }
  }
  return DeckStats(
    deck: deck,
    total: cards.length,
    mature: mature,
    due: due,
    favorites: fav,
    studied: studied,
    lastStudied: last,
  );
}

/// Deck "gabungan" berisi semua kartu berbintang.
final favoritesDeck = Deck(
  id: kFavoritesDeckId,
  name: 'Favorit',
  description: '',
  kind: 'vocab',
  createdAt: DateTime(2026),
);

final allCardsProvider = StreamProvider<List<FlashCard>>(
  (ref) => ref.watch(cardRepositoryProvider).watchAllCards(),
);

final lastReviewsProvider = StreamProvider<Map<int, DateTime>>(
  (ref) => ref.watch(cardRepositoryProvider).watchLastReviews(),
);

class HubData {
  const HubData(this.decks, this.favorites);
  final List<DeckStats> decks;
  final DeckStats favorites;
}

final hubProvider = Provider<AsyncValue<HubData>>((ref) {
  final decks = ref.watch(decksProvider);
  final cards = ref.watch(allCardsProvider);
  final last = ref.watch(lastReviewsProvider);

  final err = decks.error ?? cards.error ?? last.error;
  if (err != null) return AsyncValue.error(err, StackTrace.current);
  final d = decks.value, c = cards.value, l = last.value;
  if (d == null || c == null || l == null) return const AsyncValue.loading();

  final byDeck = <int, List<FlashCard>>{};
  for (final card in c) {
    (byDeck[card.deckId] ??= []).add(card);
  }
  return AsyncValue.data(HubData(
    [for (final deck in d) computeDeckStats(deck, byDeck[deck.id] ?? const [], l)],
    computeDeckStats(favoritesDeck, c.where((x) => x.isFavorite).toList(), l),
  ));
});