import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_gate.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_providers.dart';

void main() {
  runApp(const ProviderScope(child: LingoFlipApp()));
}

class LingoFlipApp extends ConsumerWidget {
  const LingoFlipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LingoFlip',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const AppGate(),
    );
  }
}