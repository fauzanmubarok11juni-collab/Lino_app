import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/confetti.dart';
import '../../../shared/mascot.dart';
import '../data/study_session.dart';

class StudyResult extends StatelessWidget {
  const StudyResult({
    super.key,
    required this.session,
    required this.favoriteCount,
    required this.onDone,
    this.onMistakes,
    this.onRetry,
    this.retryLabel = '',
  });

  final StudySession session;
  final int favoriteCount;
  final VoidCallback onDone;
  final VoidCallback? onMistakes;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final text = Theme.of(context).textTheme;
    final rated = s.firstRatings.length;
    final acc = s.accuracy;
    final pct = (acc * 100).round();

    final LinoMood mood;
    final String title;
    String sub;
    if (rated == 0) {
      mood = LinoMood.sleep;
      title = s.total == 0
          ? 'Tidak ada kartu jatuh tempo'
          : 'Belum ada kartu yang dinilai';
      sub = s.total == 0
          ? 'Semua kartu sudah direview. Lino mau tidur dulu.'
          : 'Mulai lagi kapan saja.';
    } else if (acc >= 0.8) {
      mood = LinoMood.cheer;
      title = 'Luar biasa!';
      sub = 'Lino bangga sama kamu!';
    } else if (acc >= 0.5) {
      mood = LinoMood.wave;
      title = 'Sesi selesai!';
      sub = 'Terus ulangi, nanti makin lancar.';
    } else {
      mood = LinoMood.sad;
      title = 'Tidak apa-apa!';
      sub = 'Kartu yang sulit akan muncul lagi supaya makin hafal.';
    }
    if (s.practice && rated > 0) {
      sub = '$sub\nMode latihan: jadwal SM-2 tidak berubah.';
    }
    final celebrate = rated > 0 && acc >= 0.8;

    return Stack(
      children: [
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Mascot(height: 190, mood: mood)),
                  const SizedBox(height: 12),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(
                          color: celebrate ? AppColors.brandText : null)),
                  const SizedBox(height: 6),
                  Text(sub, textAlign: TextAlign.center, style: text.bodyLarge),
                  if (rated > 0) ...[
                    const SizedBox(height: 20),
                    Text('$pct%',
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900, fontSize: 52)),
                    Text('akurasi percobaan pertama',
                        textAlign: TextAlign.center, style: text.bodySmall),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: _Tile(
                                value: '${s.remembered}',
                                label: 'Hafal',
                                color: AppColors.green,
                                icon: Icons.check_circle_rounded)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _Tile(
                                value: '${s.forgotten}',
                                label: 'Lupa',
                                color: AppColors.red,
                                icon: Icons.replay_rounded)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _Tile(
                                value: '$favoriteCount',
                                label: 'Favorit',
                                color: AppColors.orange,
                                icon: Icons.star_rounded)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (onMistakes != null) ...[
                    ChunkyButton(
                        label: 'Review mistakes (${s.mistakes.length})',
                        onPressed: onMistakes),
                    const SizedBox(height: 10),
                  ],
                  if (onRetry != null) ...[
                    ChunkyButton(
                      label: retryLabel,
                      color: AppColors.blue,
                      shadow: AppColors.blueDark,
                      fontSize: 15,
                      onPressed: onRetry,
                    ),
                    const SizedBox(height: 10),
                  ],
                  ChunkyButton.outlined(label: 'Selesai', onPressed: onDone),
                ],
              ),
            ),
          ),
        ),
        if (celebrate) const Positioned.fill(child: Confetti()),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 24)),
            ],
          ),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}