import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/practice_question.dart';
import '../data/practice_session.dart';
import '../providers/practice_providers.dart';

String _normalize(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

class PracticePage extends ConsumerStatefulWidget {
  const PracticePage({super.key, required this.deck, this.maxMistakes});
  final Deck deck;
  final int? maxMistakes; // null = Santai

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  List<FlashCard> _cards = [];
  PracticeSession? _session;
  String? _selected;
  final List<int> _picked = []; // indeks kata yang sudah dipilih (soal susun)
  bool _checked = false;
  bool _lastCorrect = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cards =
        await ref.read(practiceRepositoryProvider).getDeckCards(widget.deck.id);
    if (!mounted) return;
    _cards = cards;
    _begin(_sample());
  }

  List<PracticeQuestion> _sample() {
    final all = buildQuestions(_cards)..shuffle();
    return all.take(kSessionSize).toList();
  }

  void _begin(List<PracticeQuestion> qs) {
    setState(() {
      _session = PracticeSession(qs, maxMistakes: widget.maxMistakes);
      _resetQuestion();
    });
  }

  void _resetQuestion() {
    _selected = null;
    _picked.clear();
    _checked = false;
    _lastCorrect = false;
  }

  bool _canCheck(PracticeQuestion q) => q.kind == QuestionKind.choice
      ? _selected != null
      : _picked.length == q.tiles.length;

  Future<void> _check() async {
    if (_checked) return;
    final s = _session!;
    final q = s.current!;
    final bool correct;
    if (q.kind == QuestionKind.choice) {
      correct = _selected == q.answer;
    } else {
      correct = _picked.map((i) => q.tiles[i]).join(' ') == _normalize(q.answer);
    }
    s.record(correct);
    setState(() {
      _checked = true;
      _lastCorrect = correct;
    });
    await ref.read(practiceRepositoryProvider).log(q.cardId, correct);
  }

  void _next() {
    final s = _session!;
    s.advance();
    setState(_resetQuestion);
    if (s.limitReached) _showLimit();
  }

  Future<void> _showLimit() async {
    final s = _session!;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Batas kesalahan tercapai'),
        content: Text('Anda sudah salah ${s.mistakes} kali. Mau coba lagi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'exit'),
              child: const Text('Keluar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'restart'),
              child: const Text('Ulangi dari awal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, 'wrong'),
              child: const Text('Kerjakan ulang yang salah')),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'wrong':
        _begin(List.of(s.wrong));
      case 'restart':
        _begin(_sample());
      default:
        Navigator.pop(context);
    }
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari latihan?'),
        content: const Text('Sesi ini akan berakhir.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lanjut latihan')),
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
    final s = _session;
    return Scaffold(
      body: SafeArea(
        child: s == null
            ? const Center(child: CircularProgressIndicator())
            : s.total == 0
                ? _buildEmpty()
                : s.finished
                    ? _buildDone(s)
                    : _buildQuestion(s),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Deck ini belum punya soal latihan.'),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali')),
        ],
      ),
    );
  }

  Widget _buildQuestion(PracticeSession s) {
    final q = s.current!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: s.progress, minHeight: 10),
                ),
              ),
              if (s.maxMistakes != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 4),
                Text('${s.heartsLeft}',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.instruction,
                    style: text.labelLarge?.copyWith(color: scheme.primary)),
                const SizedBox(height: 12),
                if (q.prompt.isNotEmpty)
                  Text(q.prompt, style: text.headlineSmall),
                const SizedBox(height: 24),
                if (q.kind == QuestionKind.choice)
                  ...q.options.map((o) => _option(q, o))
                else
                  _orderArea(q),
              ],
            ),
          ),
        ),
        _bottomBar(s, q),
      ],
    );
  }

  Widget _option(PracticeQuestion q, String opt) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _selected == opt;
    final isAnswer = opt == q.answer;

    Color bg = Colors.transparent;
    Color border = scheme.outlineVariant;
    if (_checked) {
      if (isAnswer) {
        bg = Colors.green.withValues(alpha: 0.18);
        border = Colors.green;
      } else if (isSelected) {
        bg = Colors.red.withValues(alpha: 0.18);
        border = Colors.red;
      }
    } else if (isSelected) {
      bg = scheme.primaryContainer;
      border = scheme.primary;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: border, width: 2),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: _checked ? null : () => setState(() => _selected = opt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Text(opt, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderArea(PracticeQuestion q) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in _picked)
                ActionChip(
                  label: Text(q.tiles[i]),
                  onPressed:
                      _checked ? null : () => setState(() => _picked.remove(i)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < q.tiles.length; i++)
              _picked.contains(i)
                  ? Opacity(
                      opacity: 0.25, child: Chip(label: Text(q.tiles[i])))
                  : ActionChip(
                      label: Text(q.tiles[i]),
                      onPressed:
                          _checked ? null : () => setState(() => _picked.add(i)),
                    ),
          ],
        ),
      ],
    );
  }

  Widget _bottomBar(PracticeSession s, PracticeQuestion q) {
    if (!_checked) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canCheck(q) ? _check : null,
            child: const Text('Periksa'),
          ),
        ),
      );
    }

    final color = _lastCorrect ? Colors.green : Colors.red;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_lastCorrect ? Icons.check_circle : Icons.cancel,
                  color: color),
              const SizedBox(width: 8),
              Text(_lastCorrect ? 'Benar!' : 'Kurang tepat',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          if (!_lastCorrect) ...[
            const SizedBox(height: 8),
            Text('Jawaban benar: ${q.answer}'),
          ],
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(q.explanation),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: _next,
              child: const Text('Lanjut'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(PracticeSession s) {
    final text = Theme.of(context).textTheme;
    final perfect = s.wrong.isEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(perfect ? Icons.emoji_events : Icons.check_circle,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Latihan selesai!', style: text.headlineSmall),
            const SizedBox(height: 8),
            Text('${s.firstTryCorrect} dari ${s.total} benar di percobaan pertama',
                textAlign: TextAlign.center),
            if (s.maxMistakes != null) Text('Sisa nyawa: ${s.heartsLeft}'),
            if (!perfect) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Soal yang sempat salah', style: text.titleMedium),
              ),
              for (final q in s.wrong)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(q.prompt.isEmpty ? q.instruction : q.prompt,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(q.answer),
                ),
            ],
            const SizedBox(height: 24),
            if (!perfect)
              FilledButton.icon(
                onPressed: () => _begin(List.of(s.wrong)),
                icon: const Icon(Icons.replay),
                label: Text('Ulangi ${s.wrong.length} soal yang salah'),
              )
            else
              FilledButton.icon(
                onPressed: () => _begin(_sample()),
                icon: const Icon(Icons.refresh),
                label: const Text('Latihan lagi'),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}