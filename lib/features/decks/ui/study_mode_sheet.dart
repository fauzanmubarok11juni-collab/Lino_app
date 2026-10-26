import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../practice/ui/practice_launcher.dart';
import '../../study/ui/study_page.dart';
import '../../study/ui/type_answer_page.dart';

Future<void> showStudyModeSheet(BuildContext context, Deck deck) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Pilih mode: ${deck.name}',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          _Mode(
            icon: Icons.style,
            title: 'Study',
            subtitle: 'Balik kartu lalu nilai ingatanmu. Jadwal SM-2 ikut berubah.',
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => StudyPage(deck: deck)));
            },
          ),
          _Mode(
            icon: Icons.keyboard,
            title: 'Ketik Jawaban',
            subtitle: 'Ketik jawabannya sendiri. Jadwal SM-2 ikut berubah.',
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TypeAnswerPage(deck: deck)));
            },
          ),
          _Mode(
            icon: Icons.checklist,
            title: 'Pilihan Ganda',
            subtitle: 'Pilih jawaban dengan batas kesalahan. Jadwal tidak berubah.',
            onTap: () {
              Navigator.pop(ctx);
              startPracticeWithLevel(context, deck);
            },
          ),
          const _Mode(icon: Icons.headphones, title: 'Audio'),
          const _Mode(icon: Icons.extension, title: 'Match'),
          const _Mode(icon: Icons.timer, title: 'Timed Challenge'),
        ],
      ),
    ),
  );
}

class _Mode extends StatelessWidget {
  const _Mode(
      {required this.icon, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null
          ? const Chip(
              label: Text('Segera'), visualDensity: VisualDensity.compact)
          : null,
      onTap: onTap,
    );
  }
}