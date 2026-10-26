import 'package:flutter/material.dart';

const List<(String, Color)> kAvatars = [
  ('🌱', Color(0xFF58CC02)),
  ('🌻', Color(0xFFFFC800)),
  ('🌸', Color(0xFFCE82FF)),
  ('🍀', Color(0xFF46A302)),
  ('🍓', Color(0xFFFF4B4B)),
  ('🍄', Color(0xFFFF9600)),
  ('🦋', Color(0xFF1CB0F6)),
  ('🐞', Color(0xFFFF8A8A)),
];

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key, required this.index, this.size = 44});
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = kAvatars[index.clamp(0, kAvatars.length - 1).toInt()];
    return Semantics(
      label: 'Avatar',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 2),
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key, required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < kAvatars.length; i++)
          Semantics(
            button: true,
            selected: i == selected,
            label: 'Avatar ${i + 1}',
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == selected ? scheme.onSurface : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: AvatarBadge(index: i, size: 60),
              ),
            ),
          ),
      ],
    );
  }
}