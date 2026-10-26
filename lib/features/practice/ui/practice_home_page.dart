import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../cards/providers/card_providers.dart';
import '../../decks/providers/deck_providers.dart';
import '../../import/ui/import_page.dart';
import '../data/practice_question.dart';
import 'practice_page.dart';

class PracticeHomePage extends ConsumerWidget {
  const PracticeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Latihan')),
      body: decks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Belum ada materi untuk dilatih.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Impor materi'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ImportPage()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _DeckTile(deck: list[i]),
          );
        },
      ),
    );
  }
}

class _DeckTile extends ConsumerWidget {
  const _DeckTile({required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards =
        ref.watch(cardsByDeckProvider(deck.id)).value ?? const <FlashCard>[];
    final ready = buildQuestions(cards).length;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        enabled: ready > 0,
        leading: CircleAvatar(
          child: Icon(deck.kind == 'vocab' ? Icons.style : Icons.quiz),
        ),
        title: Text(deck.name),
        subtitle: Text(ready == 0
            ? 'Belum ada soal latihan'
            : '$ready soal siap • sesi ${min(ready, kSessionSize)} soal'),
        trailing: const Icon(Icons.play_arrow),
        onTap: () => _start(context),
      ),
    );
  }

  Widget _mode(BuildContext ctx, String label, String hint, int value) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(hint),
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final mode = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih tingkat'),
        children: [
          _mode(ctx, 'Santai', 'Tanpa batas kesalahan', 0),
          _mode(ctx, 'Normal', 'Batas 5 kesalahan', 5),
          _mode(ctx, 'Ketat', 'Batas 3 kesalahan', 3),
        ],
      ),
    );
    if (mode == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PracticePage(deck: deck, maxMistakes: mode == 0 ? null : mode),
      ),
    );
  }
}