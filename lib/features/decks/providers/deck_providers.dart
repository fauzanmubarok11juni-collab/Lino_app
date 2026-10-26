import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/deck_repository.dart';

final deckRepositoryProvider = Provider<DeckRepository>(
  (ref) => DeckRepository(ref.watch(databaseProvider)),
);

final decksProvider = StreamProvider<List<Deck>>(
  (ref) => ref.watch(deckRepositoryProvider).watchDecks(),
);