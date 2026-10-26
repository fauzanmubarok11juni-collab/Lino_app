import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'chunky_button.dart';
import 'mascot.dart';

class ThemePreviewPage extends StatelessWidget {
  const ThemePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LingoFlip')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
  alignment: WrapAlignment.center,
  spacing: 8,
  children: [
    for (final m in LinoMood.values) Mascot(height: 120, mood: m),
  ],
),
          const SizedBox(height: 16),
          Center(
            child: Text('Halo, aku Lino!',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: 24),
          ChunkyButton(label: 'Mulai belajar', onPressed: () {}),
          const SizedBox(height: 10),
          ChunkyButton(
            label: 'Ulangi soal',
            color: AppColors.blue,
            shadow: AppColors.blueDark,
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          ChunkyButton.outlined(label: 'Pulihkan backup', onPressed: () {}),
          const SizedBox(height: 10),
          const ChunkyButton(label: 'Nonaktif', onPressed: null),
        ],
      ),
    );
  }
}