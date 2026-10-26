import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_provider.dart';
import 'core/theme/app_colors.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/ui/onboarding_page.dart';
import 'features/settings/providers/settings_providers.dart';
import 'shared/chunky_button.dart';
import 'shared/mascot.dart';

/// Membuka database (dan menjalankan migrasi kalau ada) sebelum aplikasi tampil.
final bootProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.customSelect('SELECT 1').get();
});

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  bool _minTimePassed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _minTimePassed = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final f in const [
      'lino_wave', 'lino_cheer', 'lino_sad', 'lino_surprised', 'lino_sleep'
    ]) {
      precacheImage(AssetImage('assets/images/$f.png'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(bootProvider);
    final profile = ref.watch(profileProvider);
    final error = boot.hasError
        ? boot.error
        : (profile.hasError ? profile.error : null);

    final Widget child;
    if (error != null) {
      child = _BootError(
        error: '$error',
        onRetry: () {
          ref.invalidate(bootProvider);
          ref.invalidate(profileProvider);
        },
      );
    } else if (boot.hasValue && profile.hasValue && _minTimePassed) {
      child = profile.requireValue.onboarded
          ? const HomeShell()
          : const OnboardingPage();
    } else {
      child = const LoadingScreen();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: child,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: Semantics(
        label: 'Memuat LingoFlip',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Mascot(height: 230),
              const SizedBox(height: 16),
              Text(
                'LingoFlip',
                style: text.displaySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 44,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Belajar sedikit demi sedikit, tumbuh setiap hari',
                textAlign: TextAlign.center,
                style: text.bodyMedium
                    ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    color: AppColors.ink,
                    backgroundColor: Color(0x33FFFFFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(height: 170, mood: LinoMood.sad),
                const SizedBox(height: 12),
                Text('Database gagal dibuka',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.ink)),
                const SizedBox(height: 8),
                Text(error,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.ink)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 220,
                  child: ChunkyButton(
                    label: 'Coba lagi',
                    color: AppColors.blue,
                    shadow: AppColors.blueDark,
                    onPressed: onRetry,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}