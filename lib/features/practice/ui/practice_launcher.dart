import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import 'practice_page.dart';

Future<void> startPracticeWithLevel(BuildContext context, Deck deck) async {
  Widget option(BuildContext ctx, String label, String hint, int value) {
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

  final mode = await showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Pilih tingkat'),
      children: [
        option(ctx, 'Santai', 'Tanpa batas kesalahan', 0),
        option(ctx, 'Normal', 'Batas 5 kesalahan', 5),
        option(ctx, 'Ketat', 'Batas 3 kesalahan', 3),
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