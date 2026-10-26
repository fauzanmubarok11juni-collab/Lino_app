import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/srs/streak.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/mascot.dart';
import '../providers/stats_providers.dart';
import '../../../shared/avatar_badge.dart';
import '../../settings/data/profile.dart';
import '../../settings/providers/settings_providers.dart';
import '../../settings/ui/settings_page.dart';


const _dayNames = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];
const _dayShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
  'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

(LinoMood, String) _linoSays(StreakInfo s, int due, DateTime today) {
  if (s.days.contains(today)) {
    return (LinoMood.cheer, 'Hebat! Streak ${s.current} hari aman untuk hari ini.');
  }
  if (s.current > 0) {
    return (
      LinoMood.wave,
      due > 0
          ? 'Streak ${s.current} hari! Belajar hari ini supaya tidak putus.'
          : 'Streak ${s.current} hari! Kerjakan latihan soal supaya tidak putus.'
    );
  }
  if (s.days.isNotEmpty) {
    final last = s.days.reduce((a, b) => a.isAfter(b) ? a : b);
    if (today.difference(last).inDays <= 3) {
      return (LinoMood.sad, 'Streak-mu putus, tidak apa-apa. Yuk mulai lagi hari ini!');
    }
  }
  if (due == 0) {
    return (LinoMood.sleep, 'Belum ada kartu jatuh tempo. Lino mau tidur dulu.');
  }
  return (LinoMood.wave, 'Halo, aku Lino! Yuk mulai belajar.');
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    super.key,
    required this.onGoFlashcard,
    required this.onGoPractice,
  });

  final VoidCallback onGoFlashcard;
  final VoidCallback onGoPractice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider).value ?? StreakInfo.empty;
    final due = ref.watch(dueTotalProvider).value ?? 0;
    final text = Theme.of(context).textTheme;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final (mood, message) = _linoSays(streak, due, today);
    final date =
        '${_dayNames[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

        final profile = ref.watch(profileProvider).value ?? const Profile();
void openSettings() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Header
                        // Header
            Row(
              children: [
                GestureDetector(
                  onTap: openSettings,
                  child: AvatarBadge(index: profile.avatar, size: 48),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: text.bodyMedium),
                      Text(
                        'Halo, ${profile.displayName}!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineMedium?.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                ),
                _StreakPill(count: streak.current),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Pengaturan',
                  onPressed: openSettings,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lino + balon ucapan
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Mascot(height: 110, mood: mood),
                const SizedBox(width: 10),
                Expanded(child: _Bubble(text: message)),
              ],
            ),
            const SizedBox(height: 20),

            // Kalender 7 hari
            _WeekStrip(days: streak.days, today: today),
            const SizedBox(height: 20),

            // Statistik
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Jatuh tempo',
                    value: '$due',
                    unit: 'kartu',
                    color: AppColors.blue,
                    shadow: AppColors.blueDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    label: 'Streak terbaik',
                    value: '${streak.best}',
                    unit: 'hari',
                    color: AppColors.yellow,
                    shadow: AppColors.yellowDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            if (due > 0)
              ChunkyButton(label: 'Belajar sekarang', onPressed: onGoFlashcard)
            else
              ChunkyButton(
                label: 'Latihan soal',
                color: AppColors.blue,
                shadow: AppColors.blueDark,
                onPressed: onGoPractice,
              ),
          ],
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 16, 6),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF3A2A14) : const Color(0xFFFFF1DC),
        border: Border.all(
            color: dark ? const Color(0xFF7A5420) : const Color(0xFFFFC978),
            width: 2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              color: count > 0 ? AppColors.orange : Colors.grey, size: 28),
          const SizedBox(width: 4),
          Text('$count',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2C34) : const Color(0xFFF0F9FF),
        border: Border.all(
            color: dark ? const Color(0xFF37464F) : const Color(0xFFBDE6FF),
            width: 2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w700, height: 1.35),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days, required this.today});
  final Set<DateTime> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    Widget cell(DateTime d) {
      final done = days.contains(d);
      final isToday = d == today;
      Color bg = scheme.outlineVariant.withValues(alpha: 0.35);
      Border? border;
      Widget? child;
      if (done) {
        bg = AppColors.green;
        child = const Icon(Icons.check_rounded, size: 20, color: AppColors.ink);
      } else if (isToday) {
        bg = dark ? const Color(0xFF1E3A4A) : const Color(0xFFDDF4FF);
        border = Border.all(color: AppColors.blue, width: 3);
      }
      return Column(
        children: [
          Text(_dayShort[d.weekday - 1],
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: bg, shape: BoxShape.circle, border: border),
            child: child,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7 hari terakhir', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 6; i >= 0; i--)
                cell(DateTime(today.year, today.month, today.day - i)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.shadow,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    const ink = TextStyle(color: AppColors.ink);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ink.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(value,
              style: ink.copyWith(
                  fontWeight: FontWeight.w900, fontSize: 40, height: 1.1)),
          Text(unit, style: ink.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}