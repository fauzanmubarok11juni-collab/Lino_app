import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/card_providers.dart';

class CardFormPage extends ConsumerStatefulWidget {
  const CardFormPage({super.key, required this.deckId, this.card});
  final int deckId;
  final FlashCard? card;

  @override
  ConsumerState<CardFormPage> createState() => _CardFormPageState();
}

class _CardFormPageState extends ConsumerState<CardFormPage> {
  late final _front = TextEditingController(text: widget.card?.front ?? '');
  late final _back = TextEditingController(text: widget.card?.back ?? '');

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final front = _front.text.trim();
    final back = _back.text.trim();
    if (front.isEmpty || back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sisi depan dan belakang wajib diisi')),
      );
      return;
    }
    final repo = ref.read(cardRepositoryProvider);
    if (widget.card == null) {
      await repo.addCard(widget.deckId, front, back);
    } else {
      await repo.updateCard(widget.card!.id, front, back);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'Kartu baru' : 'Ubah kartu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _front,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Depan (pertanyaan)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _back,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Belakang (jawaban)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Simpan')),
            ),
          ],
        ),
      ),
    );
  }
}