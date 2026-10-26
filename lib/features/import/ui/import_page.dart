import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../data/import_parser.dart';
import '../providers/import_providers.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  List<ParsedSection>? _sections;
  String _fileName = '';
  String? _error;
  bool _busy = false;
  bool _reverse = true;

  Future<void> _pick() async {
    setState(() => _error = null);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final bytes = await file.readAsBytes();

      String text;
      if (file.name.toLowerCase().endsWith('.pdf')) {
        final doc = sf.PdfDocument(inputBytes: bytes);
        text = sf.PdfTextExtractor(doc).extractText();
        doc.dispose();
      } else {
        text = utf8.decode(bytes, allowMalformed: true);
      }

      final sections = parseImportText(text);
      if (sections.isEmpty) {
        setState(() => _error =
            'Tidak ada baris yang cocok dengan format JENIS | soal | jawaban | penjelasan | pengecoh.');
        return;
      }
      setState(() {
        _sections = sections;
        _fileName = file.name;
      });
    } catch (e) {
      setState(() => _error = 'Gagal membaca file: $e');
    }
  }

  bool _doubled(ParsedSection s, ParsedCard c) =>
      _reverse && s.deckKind == 'vocab' && c.type == 'V';

  int _count(List<ParsedSection> sections) {
    var n = 0;
    for (final s in sections) {
      for (final c in s.cards) {
        if (c.isValid) n += _doubled(s, c) ? 2 : 1;
      }
    }
    return n;
  }

  int _practiceReady(List<ParsedSection> sections) {
    var n = 0;
    for (final s in sections) {
      for (final c in s.cards) {
        if (c.isValid && c.practiceWarning == null) n++;
      }
    }
    return n;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final r = await ref
        .read(importRepositoryProvider)
        .save(_sections!, reverseVocab: _reverse);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${r.added} ditambahkan, ${r.updated} diperbarui, '
          '${r.unchanged} tidak berubah'
          '${r.newDecks > 0 ? ' • ${r.newDecks} deck baru' : ''}'),
    ));
    Navigator.pop(context);
  }

  Future<void> _edit(ParsedCard c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _EditDialog(card: c),
    );
    if (ok == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impor materi'),
        actions: [
          if (sections != null)
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Ganti file',
              onPressed: _pick,
            ),
        ],
      ),
      body: sections == null ? _buildPicker() : _buildPreview(sections),
      bottomNavigationBar: sections == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _busy || _count(sections) == 0 ? null : _save,
                  child: Text('Simpan ${_count(sections)} kartu'),
                ),
              ),
            ),
    );
  }

  Widget _buildPicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Pilih file PDF atau TXT berisi materi',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Format tiap baris:\nJENIS | soal | jawaban | penjelasan | pengecoh',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pilih file'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(List<ParsedSection> sections) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        ListTile(
          leading: const Icon(Icons.description),
          title: Text(_fileName),
          subtitle: Text('${sections.length} deck • '
              '${_practiceReady(sections)} kartu siap latihan'),
        ),
        SwitchListTile(
          title: const Text('Buat juga kartu kebalikan'),
          subtitle: const Text('Khusus vocab: Indonesia → Inggris'),
          value: _reverse,
          onChanged: (v) => setState(() => _reverse = v),
        ),
        const Divider(),
        for (final s in sections)
          ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(s.deckKind == 'vocab' ? Icons.style : Icons.quiz),
            title: Text(s.name),
            subtitle: Text(
                '${s.deckKind == 'vocab' ? 'Vocab' : 'Soal'} • ${s.cards.length} kartu'),
            children: [
              for (final c in List.of(s.cards))
                ListTile(
                  dense: true,
                  title: Text(c.front,
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    !c.isValid
                        ? 'Soal atau jawaban kosong, tidak akan disimpan'
                        : '${c.answer}'
                            '${c.practiceWarning != null ? '\n⚠ ${c.practiceWarning}' : ''}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: !c.isValid
                        ? TextStyle(color: scheme.error)
                        : c.practiceWarning != null
                            ? TextStyle(color: scheme.tertiary)
                            : null,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => s.cards.remove(c)),
                  ),
                  onTap: () => _edit(c),
                ),
            ],
          ),
      ],
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.card});
  final ParsedCard card;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _front = TextEditingController(text: widget.card.front);
  late final _answer = TextEditingController(text: widget.card.answer);
  late final _expl = TextEditingController(text: widget.card.explanation);
  late final _choices =
      TextEditingController(text: widget.card.choices.join('; '));

  @override
  void dispose() {
    _front.dispose();
    _answer.dispose();
    _expl.dispose();
    _choices.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah kartu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _front,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Soal'),
            ),
            TextField(
              controller: _answer,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Jawaban'),
            ),
            TextField(
              controller: _expl,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Penjelasan'),
            ),
            TextField(
              controller: _choices,
              maxLines: null,
              decoration: const InputDecoration(
                  labelText: 'Pengecoh (pisahkan dengan ;)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            widget.card.front = _front.text.trim();
            widget.card.answer = _answer.text.trim();
            widget.card.explanation = _expl.text.trim();
            widget.card.choices = _choices.text
                .split(';')
                .map((c) => c.trim())
                .where((c) => c.isNotEmpty)
                .toList();
            Navigator.pop(context, true);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}