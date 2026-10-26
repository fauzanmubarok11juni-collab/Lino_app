import 'dart:math';
import 'package:flutter/material.dart';

class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.showBack,
    this.onTap,
    this.frontLabel = 'Pertanyaan',
    this.backLabel = 'Jawaban',
  });

  final String front;
  final String back;
  final bool showBack;
  final VoidCallback? onTap;
  final String frontLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: showBack ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        builder: (context, v, _) {
          final isBack = v > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(v * pi),
            child: isBack
                // Putar balik sisi belakang supaya teks tidak terbalik
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _Face(text: back, label: backLabel, isBack: true),
                  )
                : _Face(text: front, label: frontLabel, isBack: false),
          );
        },
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.text, required this.label, required this.isBack});
  final String text;
  final String label;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bg = isBack
        ? (dark ? const Color(0xFF1E3A4A) : const Color(0xFFDDF4FF))
        : scheme.surface;
    final edge = isBack
        ? (dark ? const Color(0xFF2E5A70) : const Color(0xFF84D8FF))
        : scheme.outlineVariant;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: edge, width: 2),
        boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}