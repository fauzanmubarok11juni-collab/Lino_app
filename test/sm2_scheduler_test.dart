import 'package:flashcard_app/core/srs/sm2_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 10, 15, 30);
  SrsState fresh() => SrsState(
        repetitions: 0,
        easeFactor: 2.5,
        intervalDays: 0,
        dueDate: now,
      );

  test('interval berurutan 1 -> 6 -> 15 hari untuk jawaban Baik', () {
    var s = Sm2Scheduler.review(fresh(), Rating.good, now: now);
    expect(s.intervalDays, 1);
    s = Sm2Scheduler.review(s, Rating.good, now: now);
    expect(s.intervalDays, 6);
    s = Sm2Scheduler.review(s, Rating.good, now: now);
    expect(s.intervalDays, 15); // 6 * 2.5
    expect(s.dueDate, DateTime(2026, 10, 25));
  });

  test('Lagi mereset repetisi dan menurunkan ease', () {
    final s = Sm2Scheduler.review(
      SrsState(repetitions: 5, easeFactor: 2.5, intervalDays: 30, dueDate: now),
      Rating.again,
      now: now,
    );
    expect(s.repetitions, 0);
    expect(s.intervalDays, 1);
    expect(s.easeFactor, closeTo(2.3, 0.001));
  });

  test('Mudah menaikkan ease, Sulit menurunkannya', () {
    expect(Sm2Scheduler.review(fresh(), Rating.easy, now: now).easeFactor,
        closeTo(2.6, 0.001));
    expect(Sm2Scheduler.review(fresh(), Rating.hard, now: now).easeFactor,
        closeTo(2.36, 0.001));
  });

  test('ease tidak pernah di bawah 1.3', () {
    var s = fresh();
    for (var i = 0; i < 20; i++) {
      s = Sm2Scheduler.review(s, Rating.again, now: now);
    }
    expect(s.easeFactor, 1.3);
  });
}