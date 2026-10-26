import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/srs/sm2_scheduler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/chunky_button.dart';
import '../../cards/providers/card_providers.dart';
import '../data/study_session.dart';
import '../data/type_answer.dart';
import 'study_result.dart';

class TypeAnswerPage extends ConsumerStatefulWidget {
  const TypeAnswerPage({super.key, required this.deck});
  final Deck deck;

  @override
  ConsumerState<TypeAnswerPage> createState() => _TypeAnswerPageState();
}

class _TypeAnswerPageState extends ConsumerState<TypeAnswerPage> {
  final _controller = TextEditingController();
  StudySession? _s;
  bool _checked = false;
  TypeVerdict _verdict = TypeVerdict.wrong;
  String _typed = '';
  bool _busy = false;
  int _round = 0;
  final Map<int, bool> _fav = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      _resetInput();
      _round++;
    });
  }

  void _resetInput() {
    _controller.clear();
    _checked = false;
    _verdict = TypeVerdict.wrong;
    _typed = '';
  }

  void _check({bool giveUp = false}) {
    final s = _s!;
    if (_checked || s.finished) return;
    final card = s.current!;
    final v = giveUp
        ? TypeVerdict.wrong
        : checkTypedAnswer(
            _controller.text,
            expectedOf(card),
            allowTypos: allowTyposFor(card.questionType),
          );
    v == TypeVerdict.wrong
        ? HapticFeedback.mediumImpact()
        : HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _typed = _controller.text.trim();
      _verdict = v;
      _checked = true;
    });
  }

  Future<void> _continue(Rating r) async {
    final s = _s!;
    if (_busy || s.finished) return;
    _busy = true;
    try {
      final card = s.current!;
      final persist = s.rate(r);
      setState(_resetInput);
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
      case 'skip':
        if (!_checked && s.canSkip) {
          setState(() {
            s.skip();
            _resetInput();
          });
        }
      case 'shuffle':
        setState(s.shuffleRemaining);
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
    return Scaffold(appBar: _appBar(s), body: _buildQuiz(s));
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
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'skip', child: Text('Lewati kartu')),
            PopupMenuItem(value: 'shuffle', child: Text('Acak sisa kartu')),
            PopupMenuItem(value: 'finish', child: Text('Selesaikan sesi')),
          ],
        ),
      ],
    );
  }

  Widget _buildQuiz(StudySession s) {
    final card = s.current!;
    final fav = _fav[card.id] ?? false;
    final text = Theme.of(context).textTheme;
    final canCheck = _controller.text.trim().isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
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
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _QuestionCard(text: card.front),
                  const SizedBox(height: 20),
                  TextField(
                    key: ValueKey('$_round-${s.index}'),
                    controller: _controller,
                    autofocus: true,
                    readOnly: _checked,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.done,
                    style: text.titleLarge,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (!_checked && _controller.text.trim().isNotEmpty) {
                        _check();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Ketik jawabanmu',
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_checked)
            _feedback(s, card)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ChunkyButton.outlined(
                      label: 'Tidak tahu',
                      fontSize: 14,
                      onPressed: () => _check(giveUp: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ChunkyButton(
                      label: 'Periksa',
                      onPressed: canCheck ? _check : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _feedback(StudySession s, FlashCard card) {
    final text = Theme.of(context).textTheme;
    final expected = expectedOf(card);
    final (color, icon, title) = switch (_verdict) {
      TypeVerdict.correct => (AppColors.green, Icons.check_circle_rounded, 'Benar!'),
      TypeVerdict.close => (AppColors.orange, Icons.error_rounded, 'Hampir benar'),
      TypeVerdict.wrong => (AppColors.red, Icons.cancel_rounded, 'Kurang tepat'),
    };

    final String? hint = s.practice
        ? null
        : switch (_verdict) {
            TypeVerdict.correct => 'Dihitung Baik. Ketuk Mudah kalau terlalu gampang.',
            TypeVerdict.close => 'Ada salah ketik, dihitung Sulit.',
            TypeVerdict.wrong => 'Kartu ini akan muncul lagi di akhir sesi.',
          };

    final Widget buttons = switch (_verdict) {
      TypeVerdict.correct => Row(children: [
          Expanded(
            child: ChunkyButton.outlined(
                label: 'Mudah', onPressed: () => _continue(Rating.easy)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChunkyButton(
                label: 'Lanjut', onPressed: () => _continue(Rating.good)),
          ),
        ]),
      TypeVerdict.close => ChunkyButton(
          label: 'Lanjut',
          color: AppColors.orange,
          shadow: AppColors.orangeDark,
          onPressed: () => _continue(Rating.hard),
        ),
      TypeVerdict.wrong => Row(children: [
          Expanded(
            child: ChunkyButton.outlined(
                label: 'Aku benar',
                fontSize: 15,
                onPressed: () => _continue(Rating.good)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChunkyButton(
              label: 'Lanjut',
              color: AppColors.red,
              shadow: AppColors.redDark,
              fontSize: 19,
              onPressed: () => _continue(Rating.again),
            ),
          ),
        ]),
    };

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.18),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(title, style: text.titleLarge),
              ],
            ),
            if (_verdict != TypeVerdict.correct) ...[
              const SizedBox(height: 8),
              if (_verdict == TypeVerdict.close && _typed.isNotEmpty)
                Text('Jawabanmu: $_typed', style: text.bodyMedium),
              Text('Jawaban benar: $expected',
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
            if (card.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(card.explanation, style: text.bodyMedium),
            ],
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint, style: text.bodySmall),
            ],
            const SizedBox(height: 12),
            buttons,
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant, width: 2),
        boxShadow: [
          BoxShadow(color: scheme.outlineVariant, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PERTANYAAN',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}