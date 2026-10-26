import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../data/card_repository.dart';
import '../providers/card_providers.dart';
import 'card_form_page.dart';

class CardListPage extends ConsumerWidget {
  const CardListPage({super.key, required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsByDeckProvider(deck.id));
    final isFavorites = deck.id == kFavoritesDeckId;

    return Scaffold(
      appBar: AppBar(title: Text(deck.name)),
      floatingActionButton: isFavorites
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CardFormPage(deckId: deck.id)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Kartu baru'),
            ),
      body: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(isFavorites
                  ? 'Belum ada kartu favorit.'
                  : 'Deck ini belum punya kartu.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final card = list[i];
              final tile = ListTile(
                title: Text(card.front,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(card.back,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: card.isFavorite
                      ? 'Hapus dari favorit'
                      : 'Tambah ke favorit',
                  icon: Icon(
                    card.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: card.isFavorite ? AppColors.orange : null,
                  ),
                  onPressed: () => ref
                      .read(cardRepositoryProvider)
                      .setFavorite(card.id, !card.isFavorite),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CardFormPage(deckId: card.deckId, card: card),
                  ),
                ),
              );
              if (isFavorites) return tile;
              return Dismissible(
                key: ValueKey(card.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) =>
                    ref.read(cardRepositoryProvider).deleteCard(card.id),
                child: tile,
              );
            },
          );
        },
      ),
    );
  }
}