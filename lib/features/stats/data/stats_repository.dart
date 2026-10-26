import 'dart:async';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class StatsRepository {
  StatsRepository(this._db);
  final AppDatabase _db;

  /// Waktu semua aktivitas belajar: review flashcard + latihan soal.
  Stream<List<DateTime>> watchReviewTimes() {
    final reviews = _db
        .select(_db.reviewLogs)
        .watch()
        .map((rows) => rows.map((r) => r.reviewedAt).toList());
    final practice = _db
        .select(_db.practiceLogs)
        .watch()
        .map((rows) => rows.map((r) => r.practicedAt).toList());

    late final StreamController<List<DateTime>> controller;
    StreamSubscription<List<DateTime>>? subA;
    StreamSubscription<List<DateTime>>? subB;
    var a = <DateTime>[];
    var b = <DateTime>[];

    controller = StreamController<List<DateTime>>(
      onListen: () {
        subA = reviews.listen((v) {
          a = v;
          controller.add([...a, ...b]);
        }, onError: controller.addError);
        subB = practice.listen((v) {
          b = v;
          controller.add([...a, ...b]);
        }, onError: controller.addError);
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<int> watchDueTotal() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    final count = _db.cards.id.count();
    final query = _db.selectOnly(_db.cards)
      ..addColumns([count])
      ..where(_db.cards.dueDate.isSmallerThanValue(endOfToday));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }
}