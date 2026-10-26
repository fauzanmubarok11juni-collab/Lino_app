import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/srs/sm2_scheduler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/flip_card.dart';
import '../../../shared/swipe_card.dart';
import '../../cards/data/card_repository.dart';
import '../../cards/providers/card_providers.dart';
import '../data/study_session.dart';
import 'study_result.dart';

const _rates = [
  (Rating.again, 'Lagi', Color(0xFFFF8A8A), Color(0xFFE26B6B)),
  (Rating.hard, 'Sulit', AppColors.orange, AppColors.orangeDark),
  (Rating.good, 'Baik', AppColors.green, AppColors.greenDark),
  (Rating.easy, 'Mudah', AppColors.blue, AppColors.blueDark),
];

String _fmt(int days) {
  if (days < 30) return '$days hr';
  if (days < 365) return '${(days / 30).round()} bln';
  return '${(days / 365).toStringAsFixed(1)} thn';
}

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key, required this.deck});
  final Deck deck;

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  StudySession? _s;
  bool _showBack = false;
  bool _reverse = false;
  bool _busy = false;
  int _round = 0;
  final Map<int, bool> _fav = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cards =
        await ref.read(cardRepositoryProvider).getDueCards(widget.deck.id);
    if (!mounted) return;
    _begin(cards, practice: false);
  }

  void _begin(List<FlashCard> cards, {required bool practice}) {
    setState(() {
      for (final c in cards) {
        _fav.putIfAbsent(c.id, () => c.isFavorite);
      }
      _s = StudySession(cards, practice: practice);
      _showBack = false;
      _round++;
    });
  }

  void _flip() {
    HapticFeedback.selectionClick();
    setState(() => _showBack = true);
  }

  Future<void> _rate(Rating r) async {
    final s = _s!;
    if (_busy || s.finished) return;
    _busy = true;
    try {
      final card = s.current!;
      final persist = s.rate(r);
      r == Rating.again
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.lightImpact();
      setState(() => _showBack = false);
      if (persist) await ref.read(cardRepositoryProvider).reviewCard(card, r);
    } finally {
      _busy = false;
    }
  }

  Future<void> _toggleFav(FlashCard card) async {
    final v = !(_fav[card.id] ?? false);
    setState(() => _fav[card.id] = v);
    await ref.read(cardRepositoryProvider).setFavorite(card.id, v);
  }

  void _onMenu(String v) {
    final s = _s!;
    switch (v) {
      case 'shuffle':
        setState(s.shuffleRemaining);
      case 'reverse':
        setState(() {
          _reverse = !_reverse;
          _showBack = false;
        });
      case 'finish':
        setState(s.finishNow);
    }
  }

  Future<void> _confirmExit(StudySession s) async {
    if (s.firstRatings.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari sesi?'),
        content: const Text('Kartu yang sudah dinilai tetap tersimpan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lanjut belajar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (s.finished) {
      final favCount =
          s.firstRatings.keys.where((id) => _fav[id] == true).length;
      final retryCount = s.retry.length;
      return Scaffold(
        body: StudyResult(
          session: s,
          favoriteCount: favCount,
          onDone: () => Navigator.pop(context),
          onMistakes: s.practice || s.mistakes.isEmpty
              ? null
              : () => _begin(s.mistakes, practice: true),
          onRetry: retryCount == 0
              ? null
              : () => _begin(List.of(s.retry), practice: true),
          retryLabel: s.practice
              ? 'Ulangi $retryCount yang masih sulit'
              : 'Ulangi $retryCount Sulit & Baik',
        ),
      );
    }
    return Scaffold(appBar: _appBar(s), body: _buildStudy(s));
  }

  PreferredSizeWidget _appBar(StudySession s) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Keluar',
        onPressed: () => _confirmExit(s),
      ),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: s.progress),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            minHeight: 14,
            backgroundColor: scheme.outlineVariant,
            valueColor: const AlwaysStoppedAnimation(AppColors.green),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: _onMenu,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'shuffle', child: Text('Acak sisa kartu')),
            CheckedPopupMenuItem(
              value: 'reverse',
              checked: _reverse,
              child: const Text('Balik arah (jawaban dulu)'),
            ),
            const PopupMenuItem(value: 'finish', child: Text('Selesaikan sesi')),
          ],
        ),
      ],
    );
  }

  Widget _buildStudy(StudySession s) {
    final card = s.current!;
    final fav = _fav[card.id] ?? false;
    final front = _reverse ? card.back : card.front;
    final back = _reverse ? card.front : card.back;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.practice
                        ? '${s.index + 1} / ${s.queue.length} • Mode latihan (jadwal tidak berubah)'
                        : '${s.index + 1} / ${s.queue.length}',
                    style: text.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: fav ? 'Hapus dari favorit' : 'Tambah ke favorit',
                  iconSize: 30,
                  icon: Icon(
                    fav ? Icons.star_rounded : Icons.star_border_rounded,
                    color: fav ? AppColors.orange : null,
                  ),
                  onPressed: () => _toggleFav(card),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: SwipeCard(
                  key: ValueKey('$_round-${s.index}-${card.id}'),
                  enabled: _showBack,
                  onLeft: () => _rate(Rating.again),
                  onRight: () => _rate(Rating.good),
                  child: FlipCard(
                    front: front,
                    back: back,
                    showBack: _showBack,
                    onTap: _showBack ? null : _flip,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _showBack
                    ? 'Geser kartu: kiri = Lagi, kanan = Baik'
                    : 'Ketuk kartu untuk melihat jawaban',
                style: text.bodySmall,
              ),
            ),
            if (!_showBack)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ChunkyButton.outlined(
                      label: 'Lewati',
                      icon: Icons.skip_next_rounded,
                      fontSize: 14,
                      onPressed: s.canSkip
                          ? () => setState(() {
                                s.skip();
                                _showBack = false;
                              })
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ChunkyButton(
                      label: 'Balik kartu',
                      icon: Icons.flip,
                      color: AppColors.blue,
                      shadow: AppColors.blueDark,
                      onPressed: _flip,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  for (final (r, label, color, edge) in _rates)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _RateButton(
                          label: label,
                          hint: s.practice
                              ? ''
                              : _fmt(Sm2Scheduler.review(card.srs, r)
                                  .intervalDays),
                          color: color,
                          edge: edge,
                          onTap: () => _rate(r),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RateButton extends StatefulWidget {
  const _RateButton({
    required this.label,
    required this.hint,
    required this.color,
    required this.edge,
    required this.onTap,
  });

  final String label;
  final String hint;
  final Color color;
  final Color edge;
  final VoidCallback onTap;

  @override
  State<_RateButton> createState() => _RateButtonState();
}

class _RateButtonState extends State<_RateButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const ink = TextStyle(color: AppColors.ink);
    return Semantics(
      button: true,
      label: widget.hint.isEmpty
          ? widget.label
          : '${widget.label}, ${widget.hint}',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _down = true);
        },
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 64,
          margin: EdgeInsets.only(top: _down ? 4 : 0, bottom: _down ? 0 : 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: widget.edge, offset: Offset(0, _down ? 0 : 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label.toUpperCase(),
                  style: ink.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.4)),
              if (widget.hint.isNotEmpty)
                Text(widget.hint,
                    style: ink.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}