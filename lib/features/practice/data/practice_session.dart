import 'dart:math';
import 'practice_question.dart';

class PracticeSession {
  PracticeSession(List<PracticeQuestion> questions, {this.maxMistakes})
      : queue = List.of(questions),
        total = questions.length;

  final List<PracticeQuestion> queue;
  final int total;
  final int? maxMistakes; // null = mode Santai

  int index = 0;
  int mistakes = 0;
  final _seen = <int>{};
  final _correct = <int>{};
  final List<PracticeQuestion> wrong = []; // salah di percobaan pertama

  PracticeQuestion? get current => index < queue.length ? queue[index] : null;
  bool get finished => index >= queue.length;
  bool get limitReached => maxMistakes != null && mistakes >= maxMistakes!;
  int get heartsLeft =>
      maxMistakes == null ? 0 : max(0, maxMistakes! - mistakes);
  double get progress => total == 0 ? 0 : _correct.length / total;
  int get firstTryCorrect => total - wrong.length;

  /// Catat hasil jawaban untuk soal saat ini (belum pindah soal).
  void record(bool correct) {
    final q = current!;
    final firstAttempt = _seen.add(q.cardId);
    if (correct) {
      _correct.add(q.cardId);
      return;
    }
    if (firstAttempt) {
      mistakes++; // hanya percobaan pertama yang menghitung
      wrong.add(q);
    }
    queue.add(q); // muncul lagi di akhir sesi
  }

  void advance() => index++;
}
