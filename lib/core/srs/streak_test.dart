import 'package:flashcard_app/core/srs/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 10, 20);

  test('berturut-turut sampai hari ini', () {
    final s = computeStreak([
      DateTime(2026, 10, 8, 9),
      DateTime(2026, 10, 9, 21),
      DateTime(2026, 10, 10, 7),
    ], now: now);
    expect(s.current, 3);
  });

  test('hari ini belum belajar tapi kemarin sudah: streak masih hidup', () {
    final s = computeStreak(
        [DateTime(2026, 10, 8), DateTime(2026, 10, 9)], now: now);
    expect(s.current, 2);
  });

  test('bolong sehari: streak kembali 0', () {
    final s = computeStreak([DateTime(2026, 10, 7)], now: now);
    expect(s.current, 0);
  });

  test('streak terbaik dihitung dari seluruh riwayat', () {
    final s = computeStreak([
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 2),
      DateTime(2026, 9, 3),
      DateTime(2026, 10, 10),
    ], now: now);
    expect(s.best, 3);
    expect(s.current, 1);
  });
}