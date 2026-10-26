class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.days,
  });

  final int current;
  final int best;
  final Set<DateTime> days; // tanggal (jam 00.00) yang ada review-nya

  static const empty = StreakInfo(current: 0, best: 0, days: {});
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

StreakInfo computeStreak(Iterable<DateTime> reviewTimes, {DateTime? now}) {
  final today = _day(now ?? DateTime.now());
  final days = reviewTimes.map(_day).toSet();
  if (days.isEmpty) return StreakInfo.empty;

  // Streak berjalan: mulai dari hari ini, atau kemarin kalau hari ini belum belajar
  var cursor = days.contains(today)
      ? today
      : DateTime(today.year, today.month, today.day - 1);
  var current = 0;
  while (days.contains(cursor)) {
    current++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }

  // Streak terbaik sepanjang waktu
  final sorted = days.toList()..sort();
  var best = 1, run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final next = DateTime(sorted[i - 1].year, sorted[i - 1].month,
        sorted[i - 1].day + 1);
    run = sorted[i] == next ? run + 1 : 1;
    if (run > best) best = run;
  }

  return StreakInfo(current: current, best: best, days: days);
}