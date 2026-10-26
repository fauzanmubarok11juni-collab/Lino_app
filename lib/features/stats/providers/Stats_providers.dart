import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/srs/streak.dart';
import '../data/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => StatsRepository(ref.watch(databaseProvider)),
);

final streakProvider = StreamProvider<StreakInfo>(
  (ref) => ref
      .watch(statsRepositoryProvider)
      .watchReviewTimes()
      .map((times) => computeStreak(times)),
);

final dueTotalProvider = StreamProvider<int>(
  (ref) => ref.watch(statsRepositoryProvider).watchDueTotal(),
);