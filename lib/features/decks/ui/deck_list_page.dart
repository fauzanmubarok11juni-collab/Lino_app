import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/mascot.dart';
import '../../cards/data/card_repository.dart';
import '../../cards/ui/card_list_page.dart';
import '../../import/ui/import_page.dart';
import '../providers/deck_providers.dart';
import '../providers/deck_stats_providers.dart';
import 'study_mode_sheet.dart';

enum _Filter { all, learning, mastered, favorites, due }

const _filterLabels = {
  _Filter.all: 'Semua',
  _Filter.learning: 'Sedang dipelajari',
  _Filter.mastered: 'Dikuasai',
  _Filter.favorites: 'Favorit',
  _Filter.due: 'Jatuh tempo',
};

const List<(Color, Color)> _tones = [
  (AppColors.blue, AppColors.blueDark),
  (AppColors.purple, AppColors.purpleDark),
  (AppColors.yellow, AppColors.yellowDark),
  (AppColors.green, AppColors.greenDark),
  (AppColors.orange, AppColors.orangeDark),
];

String _ago(DateTime? d) {
  if (d == null) return 'belum pernah';
  final n = DateTime.now();
  final days = DateTime(n.year, n.month, n.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (days <= 0) return 'hari ini';
  if (days == 1) return 'kemarin';
  if (days < 7) return '$days hari lalu';
  if (days < 30) return '${days ~/ 7} minggu lalu';
  return '${days ~/ 30} bulan lalu';
}

class FlashcardPage extends ConsumerStatefulWidget {
  const FlashcardPage({super.key});

  @override
  ConsumerState<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends ConsumerState<FlashcardPage> {
  _Filter _filter = _Filter.all;
  String _query = '';

  bool _passes(DeckStats s) {
    if (_query.isNotEmpty &&
        !s.deck.name.toLowerCase().contains(_query.toLowerCase())) {
      return false;
    }
    return switch (_filter) {
      _Filter.all => true,
      _Filter.learning => s.learning,
      _Filter.mastered => s.mastered,
      _Filter.due => s.due > 0,
      _Filter.favorites => false,
    };
  }

  Widget _empty(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(height: 140, mood: LinoMood.sleep),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _content(HubData data) {
    if (_filter == _Filter.favorites) {
      if (data.favorites.total == 0) {
        return _empty('Belum ada kartu favorit.',
            'Beri bintang pada kartu di daftar kartu.');
      }
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          _Section(
            title: 'Favorit',
            kind: 'vocab',
            icon: Icons.star_rounded,
            items: [data.favorites],
            showAdd: false,
          ),
        ],
      );
    }

    final plain = _filter == _Filter.all && _query.isEmpty;
    final vocab = data.decks
        .where((s) => s.deck.kind == 'vocab' && _passes(s))
        .toList();
    final grammar = data.decks
        .where((s) => s.deck.kind == 'grammar' && _passes(s))
        .toList();

    if (!plain && vocab.isEmpty && grammar.isEmpty) {
      return _empty('Tidak ada deck yang cocok.',
          'Coba ganti filter atau kata pencarian.');
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        if (vocab.isNotEmpty || plain)
          _Section(
              title: 'Vocab',
              kind: 'vocab',
              icon: Icons.style,
              items: vocab,
              showAdd: plain),
        const SizedBox(height: 16),
        if (grammar.isNotEmpty || plain)
          _Section(
              title: 'Soal',
              kind: 'grammar',
              icon: Icons.quiz,
              items: grammar,
              showAdd: plain),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hub = ref.watch(hubProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Impor materi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Cari deck',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: scheme.outlineVariant.withValues(alpha: 0.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabels[f]!),
                      selected: _filter == f,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: hub.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: _content,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.title,
    required this.kind,
    required this.icon,
    required this.items,
    required this.showAdd,
  });

  final String title;
  final String kind;
  final IconData icon;
  final List<DeckStats> items;
  final bool showAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(title, style: text.titleLarge),
              const SizedBox(width: 8),
              Text('${items.length} deck', style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 256,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length + (showAdd ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              if (i == items.length) {
                return _AddTile(
                    onTap: () => _showDeckDialog(context, ref, kind));
              }
              final s = items[i];
              final virtual = s.deck.id == kFavoritesDeckId;
              return _DeckTile(
                stats: s,
                tone: virtual ? _tones[2] : _tones[s.deck.id % _tones.length],
                icon: virtual ? Icons.star_rounded : icon,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CardListPage(deck: s.deck)),
                ),
                onStudy: () => showStudyModeSheet(context, s.deck),
                onEdit: virtual
                    ? null
                    : () => _showDeckDialog(context, ref, kind, deck: s.deck),
                onDelete: virtual
                    ? null
                    : () => _confirmDelete(context, ref, s.deck),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({
    required this.stats,
    required this.tone,
    required this.icon,
    required this.onOpen,
    required this.onStudy,
    this.onEdit,
    this.onDelete,
  });

  final DeckStats stats;
  final (Color, Color) tone;
  final IconData icon;
  final VoidCallback onOpen;
  final VoidCallback onStudy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    const ink = TextStyle(color: AppColors.ink);
    final pct = (stats.progress * 100).round();

    return SizedBox(
      width: 176,
      height: 244,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: tone.$2, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: tone.$1,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: AppColors.ink, size: 22),
                      ),
                      const Spacer(),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(44, 44),
                        ),
                        tooltip: 'Mulai belajar ${stats.deck.name}',
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: AppColors.ink, size: 28),
                        onPressed: onStudy,
                      ),
                      if (onEdit != null)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppColors.ink),
                          onSelected: (v) =>
                              v == 'edit' ? onEdit!() : onDelete!(),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Ubah')),
                            PopupMenuItem(value: 'delete', child: Text('Hapus')),
                          ],
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.deck.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ink.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              height: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text('${stats.total} kartu',
                            style: ink.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stats.progress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.55),
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.ink),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('$pct% dikuasai',
                            style: ink.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                        Text('Terakhir: ${_ago(stats.lastStudied)}',
                            style: ink.copyWith(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                        if (stats.due > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('${stats.due} jatuh tempo',
                                style: ink.copyWith(
                                    fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 176,
      height: 244,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 40, color: scheme.onSurface),
              const SizedBox(height: 8),
              Text('Deck baru',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showDeckDialog(BuildContext context, WidgetRef ref, String kind,
    {Deck? deck}) async {
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (_) => _DeckDialog(deck: deck),
  );
  if (result == null) return;
  final repo = ref.read(deckRepositoryProvider);
  if (deck == null) {
    await repo.addDeck(result.$1, result.$2, kind: kind);
  } else {
    await repo.updateDeck(deck.id, result.$1, result.$2);
  }
}

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, Deck deck) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus deck?'),
      content: Text('Deck "${deck.name}" beserta semua kartunya akan dihapus.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus')),
      ],
    ),
  );
  if (ok == true) await ref.read(deckRepositoryProvider).deleteDeck(deck.id);
}

class _DeckDialog extends StatefulWidget {
  const _DeckDialog({this.deck});
  final Deck? deck;

  @override
  State<_DeckDialog> createState() => _DeckDialogState();
}

class _DeckDialogState extends State<_DeckDialog> {
  late final _name = TextEditingController(text: widget.deck?.name ?? '');
  late final _desc =
      TextEditingController(text: widget.deck?.description ?? '');

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.deck == null ? 'Deck baru' : 'Ubah deck'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama deck'),
          ),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (name, _desc.text.trim()));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}