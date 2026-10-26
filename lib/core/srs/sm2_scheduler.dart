import 'dart:math';

enum Rating { again, hard, good, easy } // index 0..3, disimpan di ReviewLogs

class SrsState {
  const SrsState({
    required this.repetitions,
    required this.easeFactor,
    required this.intervalDays,
    required this.dueDate,
  });

  final int repetitions;
  final double easeFactor;
  final int intervalDays;
  final DateTime dueDate;
}

class Sm2Scheduler {
  static const minEase = 1.3;

  static SrsState review(SrsState s, Rating rating, {DateTime? now}) {
    final n = now ?? DateTime.now();
    DateTime due(int days) => DateTime(n.year, n.month, n.day + days);

    // Gagal: ulang dari awal, besok muncul lagi
    if (rating == Rating.again) {
      return SrsState(
        repetitions: 0,
        easeFactor: max(minEase, s.easeFactor - 0.2),
        intervalDays: 1,
        dueDate: due(1),
      );
    }

    // Skala kualitas SM-2: Sulit=3, Baik=4, Mudah=5
    final q = switch (rating) {
      Rating.hard => 3,
      Rating.good => 4,
      _ => 5,
    };
    final ease = max(
      minEase,
      s.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)),
    );

    final interval = switch (s.repetitions) {
      0 => 1,
      1 => 6,
      _ => max(1, (s.intervalDays * ease).round()),
    };

    return SrsState(
      repetitions: s.repetitions + 1,
      easeFactor: ease,
      intervalDays: interval,
      dueDate: due(interval),
    );
  }
}