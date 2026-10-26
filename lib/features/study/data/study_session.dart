import 'dart:math';
import '../../../core/database/app_database.dart';
import '../../../core/srs/sm2_scheduler.dart';

class StudySession {
  StudySession(List<FlashCard> cards, {this.practice = false, Random? random})
      : _rnd = random ?? Random(),
        queue = List.of(cards),
        total = cards.length,
        _byId = {for (final c in cards) c.id: c};

  final Random _rnd;
  final List<FlashCard> queue;
  final int total;
  final bool practice; // true = ronde latihan, jadwal SM-2 tidak berubah
  final Map<int, FlashCard> _byId;

  int index = 0;
  final Map<int, Rating> firstRatings = {}; // penilaian pertama tiap kartu
  final Set<int> _failed = {}; // kartu yang sudah "Lagi" di sesi ini
  final List<FlashCard> retry = []; // kandidat ronde latihan berikutnya

  FlashCard? get current => index < queue.length ? queue[index] : null;
  bool get finished => index >= queue.length;
  double get progress => queue.isEmpty ? 0 : index / queue.length;
  bool get canSkip => queue.length - index > 1;

  int get remembered =>
      firstRatings.values.where((r) => r != Rating.again).length;
  int get forgotten =>
      firstRatings.values.where((r) => r == Rating.again).length;
  double get accuracy =>
      firstRatings.isEmpty ? 0 : remembered / firstRatings.length;

  List<FlashCard> get mistakes => [
        for (final e in firstRatings.entries)
          if (e.value == Rating.again) _byId[e.key]!,
      ];

  /// Catat penilaian untuk kartu saat ini lalu pindah ke kartu berikutnya.
  /// Mengembalikan true kalau hasilnya harus disimpan ke jadwal SM-2.
  bool rate(Rating r) {
    final card = current!;
    final persist = !practice && !_failed.contains(card.id);
    firstRatings.putIfAbsent(card.id, () => r);

    if (practice) {
      if (r == Rating.again || r == Rating.hard) retry.add(card);
    } else {
      if (r == Rating.again) {
        _failed.add(card.id);
        queue.add(card); // muncul lagi di akhir sesi
      } else if ((r == Rating.hard || r == Rating.good) &&
          !retry.any((c) => c.id == card.id)) {
        retry.add(card);
      }
    }
    index++;
    return persist;
  }

  /// Pindahkan kartu saat ini ke akhir antrean tanpa menilainya.
  void skip() {
    if (!canSkip) return;
    queue.add(queue.removeAt(index));
  }

  /// Acak kartu setelah kartu saat ini.
  void shuffleRemaining() {
    if (queue.length - index <= 2) return;
    final rest = queue.sublist(index + 1)..shuffle(_rnd);
    queue.replaceRange(index + 1, queue.length, rest);
  }

  void finishNow() => index = queue.length;
}