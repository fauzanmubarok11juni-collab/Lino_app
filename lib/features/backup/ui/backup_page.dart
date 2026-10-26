import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/mascot.dart';
import '../data/backup_format.dart';
import '../providers/backup_providers.dart';

String _two(int n) => n.toString().padLeft(2, '0');

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key, this.popOnRestore = false});
  final bool popOnRestore;

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final json = await ref.read(backupServiceProvider).export();
      final n = DateTime.now();
      final name = 'lingoflip-backup-${n.year}${_two(n.month)}${_two(n.day)}'
          '-${_two(n.hour)}${_two(n.minute)}.json';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(json);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        title: 'Backup LingoFlip',
      ));
    } catch (e) {
      _snack('Gagal membuat backup: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(BackupInfo i) {
    final t = i.exportedAt;
    final when = t == null
        ? 'tanggal tidak diketahui'
        : '${t.day}/${t.month}/${t.year} ${_two(t.hour)}.${_two(t.minute)}';
    return 'Backup tanggal $when berisi '
        '${i.countOf('decks')} deck, ${i.countOf('cards')} kartu, '
        '${i.countOf('review_logs')} riwayat review, dan '
        '${i.countOf('practice_logs')} riwayat latihan.\n\n'
        'Semua data di aplikasi sekarang akan DIGANTI dengan isi backup ini.';
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);
      if (files.isEmpty) return;
      final bytes = await files.first.readAsBytes();
      final service = ref.read(backupServiceProvider);
      final info = decodeBackup(
        utf8.decode(bytes, allowMalformed: true),
        currentSchemaVersion: service.schemaVersion,
      );

      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pulihkan backup?'),
          content: Text(_describe(info)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.ink),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ganti data')),
          ],
        ),
      );
      if (ok != true) return;

      await service.restore(info);
      _snack('Data berhasil dipulihkan.');      
      if (widget.popOnRestore && mounted) Navigator.pop(context);
    } on BackupException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Gagal memulihkan, data Anda tidak berubah. ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cadangan data')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: Mascot(height: 150)),
          const SizedBox(height: 12),
          Text('Simpan kemajuan belajarmu',
              textAlign: TextAlign.center, style: text.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Semua data hanya ada di HP ini. Backup berisi seluruh deck, kartu, '
            'jadwal belajar, streak, dan riwayat latihan.\n\n'
            'Kirim file backup ke Google Drive atau WhatsApp (chat dengan diri '
            'sendiri) supaya aman kalau HP hilang atau aplikasi terhapus. '
            'Sebaiknya dilakukan seminggu sekali, dan wajib sebelum memasang '
            'versi aplikasi baru.',
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          const SizedBox(height: 28),
          ChunkyButton(
            label: 'Simpan backup',
            icon: Icons.ios_share,
            onPressed: _busy ? null : _export,
          ),
          const SizedBox(height: 12),
          ChunkyButton.outlined(
            label: 'Pulihkan backup',
            icon: Icons.restore,
            onPressed: _busy ? null : _restore,
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}