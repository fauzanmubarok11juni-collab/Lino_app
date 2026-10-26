import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/profile.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final profileProvider = StreamProvider<Profile>(
  (ref) => ref.watch(settingsRepositoryProvider).watchAll().map(Profile.fromMap),
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final theme = ref.watch(profileProvider).value?.theme;
  return switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});