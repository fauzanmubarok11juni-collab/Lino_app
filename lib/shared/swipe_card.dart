import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Membungkus kartu agar bisa digeser kiri/kanan. Hanya aktif kalau [enabled].
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.child,
    required this.enabled,
    required this.onLeft,
    required this.onRight,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  double _dx = 0, _from = 0, _to = 0, _width = 300;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      setState(() => _dx =
          _from + (_to - _from) * Curves.easeOut.transform(_c.value));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go(double to, [VoidCallback? done]) {
    _from = _dx;
    _to = to;
    _c.forward(from: 0).whenComplete(() {
      if (mounted) done?.call();
    });
  }

  void _end(DragEndDetails d) {
    if (_gone) return;
    final v = d.primaryVelocity ?? 0;
    final threshold = _width * 0.28;
    if (_dx > threshold || (v > 800 && _dx > 24)) {
      _gone = true;
      _go(_width * 1.3, widget.onRight);
    } else if (_dx < -threshold || (v < -800 && _dx < -24)) {
      _gone = true;
      _go(-_width * 1.3, widget.onLeft);
    } else {
      _go(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _width = constraints.maxWidth;
      final p = (_dx.abs() / (_width * 0.28)).clamp(0.0, 1.0);
      final right = _dx > 0;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: widget.enabled ? (_) => _c.stop() : null,
        onHorizontalDragUpdate: widget.enabled
            ? (d) {
                if (_gone) return;
                setState(() => _dx += d.delta.dx);
              }
            : null,
        onHorizontalDragEnd: widget.enabled ? _end : null,
        child: Transform.translate(
          offset: Offset(_dx, 0),
          child: Transform.rotate(
            angle: _dx / _width * 0.3,
            child: Stack(
              children: [
                widget.child,
                if (p > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: p,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: (right ? AppColors.green : AppColors.red)
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    right
                                        ? Icons.check_rounded
                                        : Icons.replay_rounded,
                                    size: 80,
                                    color: AppColors.ink),
                                Text(right ? 'Baik' : 'Lagi',
                                    style: const TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}