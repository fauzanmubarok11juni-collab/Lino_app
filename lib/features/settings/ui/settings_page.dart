import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/avatar_badge.dart';
import '../../../shared/chunky_button.dart';
import '../../backup/ui/backup_page.dart';
import '../../import/ui/import_page.dart';
import '../data/profile.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).value ?? const Profile();
    final repo = ref.read(settingsRepositoryProvider);
    final text = Theme.of(context).textTheme;

    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(t, style: text.titleSmall?.copyWith(letterSpacing: 0.4)),
        );

    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          section('Profil'),
          ListTile(
            leading: AvatarBadge(index: p.avatar, size: 52),
            title: Text(p.displayName, style: text.titleMedium),
            subtitle: const Text('Ketuk untuk mengubah nama dan avatar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _ProfileSheet(profile: p),
            ),
          ),
          section('Target harian (XP)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final g in kDailyGoals)
                  ButtonSegment(value: g, label: Text('$g')),
              ],
              selected: {p.dailyGoalXp},
              onSelectionChanged: (s) =>
                  repo.set('dailyGoalXp', '${s.first}'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Sekitar ${p.goalCards} kartu per hari. Dipakai untuk lingkaran '
              'progres harian (segera hadir).',
              style: text.bodySmall,
            ),
          ),
          section('Tampilan'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'system', label: Text('Sistem')),
                ButtonSegment(value: 'light', label: Text('Terang')),
                ButtonSegment(value: 'dark', label: Text('Gelap')),
              ],
              selected: {p.theme},
              onSelectionChanged: (s) => repo.set('theme', s.first),
            ),
          ),
          section('Bahasa belajar'),
          const ListTile(
            leading: Icon(Icons.translate),
            title: Text('Inggris'),
            subtitle: Text('Jepang, Korea, Arab, dan Mandarin segera hadir'),
            trailing: Icon(Icons.check_circle),
          ),
          section('Data'),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Cadangan data'),
            subtitle: const Text('Simpan dan pulihkan backup JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const BackupPage()),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Impor materi'),
            subtitle: const Text('Tambah deck dari file PDF atau TXT'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const ImportPage()),
          ),
          section('Lainnya'),
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text('Ulangi pengenalan'),
            subtitle: const Text('Ubah nama, avatar, dan target dari awal'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Ulangi pengenalan?'),
                  content: const Text(
                      'Deck, kartu, jadwal belajar, dan streak tidak berubah.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Ulangi')),
                  ],
                ),
              );
              if (ok != true) return;
              await repo.set('onboarded', '0');
              if (context.mounted) {
                Navigator.popUntil(context, (r) => r.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  late final _name = TextEditingController(text: widget.profile.name);
  late int _avatar = widget.profile.avatar;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(settingsRepositoryProvider).setMany({
      'name': _name.text.trim(),
      'avatar': '$_avatar',
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Nama panggilan'),
            ),
            const SizedBox(height: 16),
            AvatarPicker(
              selected: _avatar,
              onChanged: (i) => setState(() => _avatar = i),
            ),
            const SizedBox(height: 24),
            ChunkyButton(
              label: 'Simpan',
              onPressed: _name.text.trim().isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}