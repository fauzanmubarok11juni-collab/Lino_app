import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/practice_repository.dart';

final practiceRepositoryProvider = Provider<PracticeRepository>(
  (ref) => PracticeRepository(ref.watch(databaseProvider)),
);
