import 'dart:math';
import 'package:flashcard_app/core/database/app_database.dart';
import 'package:flashcard_app/core/srs/sm2_scheduler.dart';
import 'package:flashcard_app/features/study/data/study_session.dart';
import 'package:flutter_test/flutter_test.dart';

FlashCard c(int id) => FlashCard(
      id: id,
      deckId: 1,
      front: 'f$id',
      back: 'b$id',
      questionType: 'basic',
      answer: '',
      choices: '',
      explanation: '',
      isFavorite: false,
      repetitions: 0,
      easeFactor: 2.5,
      intervalDays: 0,
      dueDate: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('Lagi: kartu diulang di akhir, pengulangan tidak mengubah jadwal', () {
    final s = StudySession([c(1), c(2)]);
    expect(s.rate(Rating.again), isTrue);
    expect(s.queue.length, 3);
    s.rate(Rating.good);
    expect(s.current!.id, 1);
    expect(s.rate(Rating.good), isFalse);
    expect(s.finished, isTrue);
    expect(s.forgotten, 1);
    expect(s.remembered, 1);
    expect(s.accuracy, 0.5);
    expect(s.mistakes.map((x) => x.id), [1]);
  });

  test('ronde latihan tidak pernah menyimpan jadwal', () {
    final s = StudySession([c(1), c(2)], practice: true);
    expect(s.rate(Rating.hard), isFalse);
    expect(s.rate(Rating.good), isFalse);
    expect(s.retry.map((x) => x.id), [1]);
  });

  test('Sulit dan Baik masuk daftar ulangi, Mudah tidak', () {
    final s = StudySession([c(1), c(2), c(3)]);
    s.rate(Rating.hard);
    s.rate(Rating.good);
    s.rate(Rating.easy);
    expect(s.retry.map((x) => x.id), [1, 2]);
  });

  test('lewati memindahkan kartu ke akhir tanpa menilai', () {
    final s = StudySession([c(1), c(2), c(3)]);
    s.skip();
    expect(s.queue.map((x) => x.id), [2, 3, 1]);
    expect(s.current!.id, 2);
    expect(s.firstRatings, isEmpty);
    final single = StudySession([c(1)]);
    expect(single.canSkip, isFalse);
  });

  test('acak sisa kartu tidak mengubah kartu saat ini', () {
    final s = StudySession([for (var i = 1; i <= 10; i++) c(i)],
        random: Random(3));
    s.shuffleRemaining();
    expect(s.current!.id, 1);
    expect(s.queue.map((x) => x.id).toSet(), {for (var i = 1; i <= 10; i++) i});
  });

  test('selesaikan sesi lebih awal', () {
    final s = StudySession([c(1), c(2)]);
    s.rate(Rating.again);
    s.finishNow();
    expect(s.finished, isTrue);
    expect(s.mistakes.length, 1);
  });
}