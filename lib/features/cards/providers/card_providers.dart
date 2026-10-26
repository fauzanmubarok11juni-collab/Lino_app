import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/card_repository.dart';

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(ref.watch(databaseProvider)),
);

final cardsByDeckProvider = StreamProvider.family<List<FlashCard>, int>(
  (ref, deckId) => ref.watch(cardRepositoryProvider).watchCards(deckId),
);

final dueCountProvider = StreamProvider.family<int, int>(
  (ref, deckId) => ref.watch(cardRepositoryProvider).watchDueCount(deckId),
);