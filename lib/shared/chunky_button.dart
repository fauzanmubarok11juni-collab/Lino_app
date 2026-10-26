import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';

class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.green,
    this.shadow = AppColors.greenDark,
    this.height = 56,
    this.fontSize = 17,
    this.icon,
  }) : outlined = false;

  const ChunkyButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.fontSize = 16,
    this.icon,
  })  : color = Colors.transparent,
        shadow = AppColors.border,
        outlined = true;

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadow;
  final double height;
  final double fontSize;
  final IconData? icon;
  final bool outlined;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const _depth = 5.0;
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    final Color face, edge, fg;
    if (!enabled) {
      face = scheme.outlineVariant;
      edge = scheme.outlineVariant;
      fg = scheme.onSurface.withValues(alpha: 0.4);
    } else if (widget.outlined) {
      face = scheme.surface;
      edge = scheme.outlineVariant;
      fg = scheme.onSurface;
    } else {
      face = widget.color;
      edge = widget.shadow;
      fg = AppColors.ink;
    }

    final pressed = _down && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled
            ? (_) {
                HapticFeedback.selectionClick();
                _set(true);
              }
            : null,
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: SizedBox(
          height: widget.height + _depth,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                top: pressed ? _depth : 0,
                left: 0,
                right: 0,
                height: widget.height,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(16),
                    border: widget.outlined
                        ? Border.all(color: edge, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: edge,
                        offset: Offset(0, pressed ? 0 : _depth),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: fg, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w900,
                            fontSize: widget.fontSize,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}