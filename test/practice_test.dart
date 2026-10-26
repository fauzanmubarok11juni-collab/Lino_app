import 'dart:math';
import 'package:flashcard_app/core/database/app_database.dart';
import 'package:flashcard_app/features/practice/data/practice_question.dart';
import 'package:flashcard_app/features/practice/data/practice_session.dart';
import 'package:flutter_test/flutter_test.dart';

FlashCard card(int id, String type, String front, String answer,
        {String choices = ''}) =>
    FlashCard(
      id: id,
      deckId: 1,
      front: front,
      back: answer,
      questionType: type,
      answer: answer,
      choices: choices,
      explanation: '',
      isFavorite: false,
      repetitions: 0,
      easeFactor: 2.5,
      intervalDays: 0,
      dueDate: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

PracticeQuestion q(int id) => PracticeQuestion(
      cardId: id,
      kind: QuestionKind.choice,
      instruction: '',
      prompt: '',
      answer: 'a',
      options: ['a', 'b'],
    );

void main() {
  final rnd = Random(1);

  test('vocab: pengecoh sama arah, tidak bercampur dengan arah kebalikan', () {
    final cards = [
      card(1, 'V', 'book', 'buku'),
      card(2, 'V', 'buku', 'book'),
      card(3, 'V', 'pen', 'pena'),
      card(4, 'V', 'pena', 'pen'),
      card(5, 'V', 'table', 'meja'),
      card(6, 'V', 'meja', 'table'),
    ];
    final qs = buildQuestions(cards, random: rnd);
    expect(qs.length, 6);
    final forward = qs.firstWhere((x) => x.cardId == 1);
    final reverse = qs.firstWhere((x) => x.cardId == 2);
    expect(forward.options.toSet(), {'buku', 'pena', 'meja'});
    expect(reverse.options.toSet(), {'book', 'pen', 'table'});
  });

  test('pilihan ganda memuat jawaban + pengecoh; tanpa pengecoh dilewati', () {
    final qs = buildQuestions([
      card(1, 'MC', 'He ___ a teacher.', 'is', choices: '["am","are"]'),
      card(2, 'TR', 'Terjemahkan:\nSaya guru.', 'I am a teacher.'),
      card(3, 'basic', 'x', 'y'),
    ], random: rnd);
    expect(qs.length, 1);
    expect(qs[0].options.toSet(), {'is', 'am', 'are'});
  });

  test('petunjuk soal dipisah dari teks soal', () {
    final qs = buildQuestions([
      card(1, 'FIB', 'Lengkapi kalimat:\nI ___ a boy.', 'am',
          choices: '["is","are"]'),
    ], random: rnd);
    expect(qs[0].prompt, 'I ___ a boy.');
    expect(qs[0].instruction, 'Lengkapi kalimat');
  });

  test('soal susun kalimat memecah jawaban menjadi kata', () {
    final qs = buildQuestions(
        [card(1, 'ORD', 'x', 'My name is Ayu.')], random: rnd);
    expect(qs[0].kind, QuestionKind.order);
    expect(qs[0].tiles.length, 4);
    expect(qs[0].tiles.toSet(), {'My', 'name', 'is', 'Ayu.'});
  });

  test('sesi: salah di percobaan pertama menghitung, pengulangan tidak', () {
    final s = PracticeSession([q(1), q(2)], maxMistakes: 3);
    s.record(false);
    s.advance();
    expect(s.mistakes, 1);
    expect(s.queue.length, 3);
    s.record(true);
    s.advance();
    s.record(false); // soal 1 diulang dan salah lagi
    s.advance();
    expect(s.mistakes, 1);
    s.record(true);
    s.advance();
    expect(s.finished, isTrue);
    expect(s.wrong.length, 1);
    expect(s.progress, 1.0);
  });

  test('batas kesalahan tercapai; mode santai tanpa batas', () {
    final s = PracticeSession([q(1), q(2)], maxMistakes: 2);
    s.record(false);
    s.advance();
    expect(s.limitReached, isFalse);
    s.record(false);
    expect(s.limitReached, isTrue);
    expect(s.heartsLeft, 0);

    final relaxed = PracticeSession([q(1)]);
    relaxed.record(false);
    expect(relaxed.limitReached, isFalse);
  });
}