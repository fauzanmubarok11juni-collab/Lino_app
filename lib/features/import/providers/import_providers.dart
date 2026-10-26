import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/import_repository.dart';

final importRepositoryProvider = Provider<ImportRepository>(
  (ref) => ImportRepository(ref.watch(databaseProvider)),
);