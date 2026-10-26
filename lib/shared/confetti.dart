import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

const _colors = [
  AppColors.green,
  AppColors.blue,
  AppColors.yellow,
  AppColors.orange,
  AppColors.purple,
  AppColors.red,
];

class _Piece {
  _Piece(Random r)
      : x = r.nextDouble(),
        delay = r.nextDouble() * 0.3,
        fall = 0.75 + r.nextDouble() * 0.6,
        swayAmp = 0.02 + r.nextDouble() * 0.05,
        swayFreq = 2 + r.nextDouble() * 4,
        phase = r.nextDouble() * pi * 2,
        spin = (r.nextDouble() - 0.5) * 14,
        w = 6 + r.nextDouble() * 6,
        h = 10 + r.nextDouble() * 8,
        round = r.nextInt(4) == 0,
        color = _colors[r.nextInt(_colors.length)];

  final double x, delay, fall, swayAmp, swayFreq, phase, spin, w, h;
  final bool round;
  final Color color;
}

class Confetti extends StatefulWidget {
  const Confetti({super.key, this.count = 70});
  final int count;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();
  final _rnd = Random();
  late final List<_Piece> _pieces =
      List.generate(widget.count, (_) => _Piece(_rnd));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _Painter(_pieces, _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0 || lt >= 1) continue;
      final y = -0.08 + lt * p.fall * 1.25;
      final x = p.x + sin(lt * p.swayFreq * pi + p.phase) * p.swayAmp;
      final opacity = lt > 0.85 ? (1 - lt) / 0.15 : 1.0;
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.spin * lt * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
          Radius.circular(p.round ? p.w : 2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.t != t;
}