import 'package:flutter/material.dart';

enum LinoMood { wave, cheer, sad, surprised, sleep }

class _Look {
  const _Look(this.asset, this.label, this.ms, this.dy, this.rot, this.scale);
  final String asset;
  final String label;
  final int ms; // durasi satu siklus gerak
  final double dy; // naik-turun (piksel)
  final double rot; // goyang (radian)
  final double scale; // tarik napas (0.03 = 3%)
}

const _looks = {
  LinoMood.wave: _Look('lino_wave',
      'Lino, maskot tunas hijau yang sedang melambai', 1600, 8, 0.05, 0),
  LinoMood.cheer: _Look('lino_cheer',
      'Lino bersorak dengan kedua tangan terangkat', 650, 14, 0.06, 0),
  LinoMood.sad: _Look(
      'lino_sad', 'Lino sedih dengan mata berkaca-kaca', 2600, 3, 0.02, 0),
  LinoMood.surprised:
      _Look('lino_surprised', 'Lino terkejut', 520, 0, 0, 0.04),
  LinoMood.sleep: _Look('lino_sleep', 'Lino tertidur', 3000, 0, 0, 0.03),
};

class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.height = 200,
    this.mood = LinoMood.wave,
    this.animate = true,
  });

  final double height;
  final LinoMood mood;
  final bool animate;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  _Look get _look => _looks[widget.mood]!;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood || old.animate != widget.animate) _start();
  }

  void _start() {
    _controller.stop();
    if (!widget.animate) return;
    _controller.duration = Duration(milliseconds: _look.ms);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = _look;
    final image = Image.asset(
      'assets/images/${look.asset}.png',
      height: widget.height,
      semanticLabel: look.label,
      gaplessPlayback: true,
    );
    // Hormati pengaturan "kurangi animasi" di HP
    if (!widget.animate || MediaQuery.of(context).disableAnimations) {
      return image;
    }
    return AnimatedBuilder(
      animation: _curve,
      child: image,
      builder: (_, child) {
        final t = _curve.value;
        return Transform.translate(
          offset: Offset(0, -look.dy * t),
          child: Transform.rotate(
            angle: (t - 0.5) * look.rot,
            child: Transform.scale(
              scale: 1 + look.scale * t,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}