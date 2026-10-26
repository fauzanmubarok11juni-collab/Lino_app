import 'dart:convert';
import 'dart:math';
import '../../../core/database/app_database.dart';

const kSessionSize = 10;

enum QuestionKind { choice, order }

class PracticeQuestion {
  PracticeQuestion({
    required this.cardId,
    required this.kind,
    required this.instruction,
    required this.prompt,
    required this.answer,
    this.options = const [],
    this.tiles = const [],
    this.explanation = '',
  });

  final int cardId;
  final QuestionKind kind;
  final String instruction; // petunjuk, misalnya "Lengkapi kalimat"
  final String prompt; // teks soal
  final String answer;
  final List<String> options; // untuk pilihan ganda (sudah diacak)
  final List<String> tiles; // untuk susun kalimat (sudah diacak)
  final String explanation;
}

const _instructions = {
  'V': 'Pilih arti yang tepat',
  'MC': 'Pilih jawaban yang benar',
  'FIB': 'Lengkapi kalimat',
  'ERR': 'Pilih perbaikan yang benar',
  'TR': 'Pilih terjemahan yang benar',
  'ORD': 'Susun kalimat yang benar',
  'TRF': 'Pilih bentuk yang benar',
  'IRR': 'Pilih bentuk yang benar',
};

List<String> _decodeChoices(String raw) {
  if (raw.isEmpty) return const [];
  try {
    final d = jsonDecode(raw);
    if (d is List) return d.map((e) => e.toString()).toList();
  } catch (_) {}
  return const [];
}

List<String> _shuffledWords(List<String> words, Random rnd) {
  final copy = List.of(words);
  for (var i = 0; i < 10; i++) {
    copy.shuffle(rnd);
    if (copy.join(' ') != words.join(' ')) break;
  }
  return copy;
}

/// Mengubah kartu di satu deck menjadi soal latihan.
/// Kartu tanpa data latihan dilewati (tetap jadi flashcard biasa).
List<PracticeQuestion> buildQuestions(List<FlashCard> cards, {Random? random}) {
  final rnd = random ?? Random();
  final out = <PracticeQuestion>[];

  // --- Kosakata: pengecoh dari kartu lain yang arahnya sama ---
  final vCards = cards
      .where((c) =>
          c.questionType == 'V' &&
          c.front.trim().isNotEmpty &&
          c.answer.trim().isNotEmpty)
      .toList();
  final pair = {for (final c in vCards) '${c.front}\u0000${c.answer}': c};

  // Kartu kebalikan = pasangan cermin dengan id lebih besar
  int dir(FlashCard c) {
    final m = pair['${c.answer}\u0000${c.front}'];
    return (m != null && m.id < c.id) ? 1 : 0;
  }

  final pools = <int, List<String>>{0: [], 1: []};
  for (final c in vCards) {
    final p = pools[dir(c)]!;
    if (!p.contains(c.answer)) p.add(c.answer);
  }
  for (final c in vCards) {
    final others = pools[dir(c)]!.where((a) => a != c.answer).toList()
      ..shuffle(rnd);
    if (others.length < 2) continue;
    final options = [c.answer, ...others.take(3)]..shuffle(rnd);
    out.add(PracticeQuestion(
      cardId: c.id,
      kind: QuestionKind.choice,
      instruction: _instructions['V']!,
      prompt: c.front,
      answer: c.answer,
      options: options,
    ));
  }

  // --- Jenis soal lain ---
  for (final c in cards) {
    final t = c.questionType;
    if (t == 'V' || t == 'basic') continue;
    final answer = c.answer.trim();
    if (answer.isEmpty) continue;

    if (t == 'ORD') {
      final words = answer.split(RegExp(r'\s+'));
      if (words.length < 2) continue;
      out.add(PracticeQuestion(
        cardId: c.id,
        kind: QuestionKind.order,
        instruction: _instructions['ORD']!,
        prompt: '',
        answer: answer,
        tiles: _shuffledWords(words, rnd),
        explanation: c.explanation,
      ));
      continue;
    }

    final distractors = _decodeChoices(c.choices)
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty && d.toLowerCase() != answer.toLowerCase())
        .toSet()
        .toList()
      ..shuffle(rnd);
    if (distractors.length < 2) continue;

    // Buang baris petunjuk ("Lengkapi kalimat:") dari soal; petunjuk tampil terpisah
    var prompt = c.front;
    final nl = prompt.indexOf('\n');
    if (t != 'MC' && nl >= 0) prompt = prompt.substring(nl + 1);

    final options = [answer, ...distractors.take(3)]..shuffle(rnd);
    out.add(PracticeQuestion(
      cardId: c.id,
      kind: QuestionKind.choice,
      instruction: _instructions[t] ?? 'Pilih jawaban yang benar',
      prompt: prompt,
      answer: answer,
      options: options,
      explanation: c.explanation,
    ));
  }

  return out;
}
