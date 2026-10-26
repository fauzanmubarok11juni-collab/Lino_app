import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/avatar_badge.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/mascot.dart';
import '../../backup/ui/backup_page.dart';
import '../../settings/data/profile.dart';
import '../../settings/providers/settings_providers.dart';

const _goalNames = {100: 'Santai', 200: 'Normal', 300: 'Serius', 400: 'Intens'};

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _lastPage = 3;
  final _pages = PageController();
  late final TextEditingController _name;
  int _page = 0;
  int _avatar = 0;
  int _goal = 200;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Kalau pengenalan diulang dari Pengaturan, isian lama ditampilkan kembali
    final p = ref.read(profileProvider).value ?? const Profile();
    _name = TextEditingController(text: p.name);
    _avatar = p.avatar;
    _goal = p.dailyGoalXp;
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _go(int page) {
    FocusScope.of(context).unfocus();
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(settingsRepositoryProvider).setMany({
      'name': _name.text.trim(),
      'avatar': '$_avatar',
      'dailyGoalXp': '$_goal',
      'language': 'en',
      'onboarded': '1',
    });
    // AppGate otomatis berpindah ke Dashboard setelah ini
  }

  @override
  Widget build(BuildContext context) {
    final canNext = _page != 1 || _name.text.trim().isNotEmpty;
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                page: _page,
                total: _lastPage + 1,
                onBack: _page > 0 ? () => _go(_page - 1) : null,
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _welcome(),
                    _namePage(),
                    _avatarPage(),
                    _goalPage(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _buttons(canNext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttons(bool canNext) {
    if (_page == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChunkyButton(label: 'Mulai', onPressed: () => _go(1)),
          const SizedBox(height: 10),
          ChunkyButton.outlined(
            label: 'Pulihkan backup',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BackupPage(popOnRestore: true)),
            ),
          ),
        ],
      );
    }
    if (_page == _lastPage) {
      return ChunkyButton(
        label: 'Mulai belajar',
        onPressed: _saving ? null : _finish,
      );
    }
    return ChunkyButton(
      label: 'Lanjut',
      onPressed: canNext ? () => _go(_page + 1) : null,
    );
  }

  Widget _layout({
    required LinoMood mood,
    required String title,
    String? subtitle,
    Widget? body,
    double mascotHeight = 170,
  }) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          Mascot(height: mascotHeight, mood: mood),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: text.headlineMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: text.bodyLarge),
          ],
          if (body != null) ...[const SizedBox(height: 24), body],
        ],
      ),
    );
  }

  Widget _welcome() => _layout(
        mood: LinoMood.wave,
        mascotHeight: 240,
        title: 'Halo, aku Lino!',
        subtitle:
            'Aku akan menemanimu belajar bahasa Inggris, sedikit demi sedikit, setiap hari.',
      );

  Widget _namePage() {
    final scheme = Theme.of(context).colorScheme;
    return _layout(
      mood: LinoMood.wave,
      title: 'Siapa namamu?',
      subtitle: 'Aku akan memanggilmu dengan nama ini.',
      body: TextField(
        controller: _name,
        maxLength: 20,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (_name.text.trim().isNotEmpty) _go(2);
        },
        decoration: InputDecoration(
          hintText: 'Nama panggilan',
          filled: true,
          fillColor: scheme.outlineVariant.withValues(alpha: 0.25),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _avatarPage() => _layout(
        mood: LinoMood.cheer,
        title: 'Pilih avatarmu',
        subtitle: 'Ini akan tampil di Dashboard.',
        body: AvatarPicker(
          selected: _avatar,
          onChanged: (i) => setState(() => _avatar = i),
        ),
      );

  Widget _goalPage() {
    final text = Theme.of(context).textTheme;
    return _layout(
      mood: LinoMood.surprised,
      mascotHeight: 130,
      title: 'Berapa targetmu tiap hari?',
      subtitle: 'Target dihitung dalam XP. Satu kartu yang benar sekitar 10 XP.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bahasa yang dipelajari', style: text.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Chip(
                avatar: Icon(Icons.check_circle, size: 18),
                label: Text('Inggris'),
              ),
              for (final l in const ['Jepang', 'Korea', 'Arab', 'Mandarin'])
                Opacity(
                  opacity: 0.5,
                  child: Chip(label: Text('$l • Segera')),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Target harian', style: text.titleSmall),
          const SizedBox(height: 8),
          for (final g in kDailyGoals) ...[
            _GoalTile(
              xp: g,
              selected: _goal == g,
              onTap: () => setState(() => _goal = g),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.page, required this.total, this.onBack});
  final int page;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: onBack == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Kembali',
                    onPressed: onBack,
                  ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < total; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: i == page ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= page ? AppColors.green : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.xp,
    required this.selected,
    required this.onTap,
  });
  final int xp;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.green.withValues(alpha: 0.18)
            : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.green : scheme.outlineVariant,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_goalNames[xp] ?? '$xp XP', style: text.titleMedium),
                      Text('sekitar ${xp ~/ 10} kartu per hari',
                          style: text.bodySmall),
                    ],
                  ),
                ),
                Text('$xp XP', style: text.titleMedium),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: AppColors.green),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
