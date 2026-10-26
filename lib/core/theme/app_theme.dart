import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? const Color(0xFF131F24) : Colors.white;
    final line = dark ? const Color(0xFF37464F) : AppColors.border;
    final text = dark ? const Color(0xFFF1F7FB) : AppColors.ink;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: b,
    ).copyWith(
      primary: AppColors.green,
      onPrimary: AppColors.ink,
      secondary: AppColors.blue,
      onSecondary: AppColors.ink,
      tertiary: AppColors.orange,
      onTertiary: AppColors.ink,
      error: AppColors.red,
      onError: AppColors.ink,
      surface: bg,
      onSurface: text,
      outlineVariant: line,
    );

    final base = ThemeData(brightness: b, fontFamily: 'Nunito')
        .textTheme
        .apply(bodyColor: text, displayColor: text);
    final textTheme = base.copyWith(
      headlineMedium:
          base.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: 'Nunito',
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge
            ?.copyWith(fontSize: 26, fontWeight: FontWeight.w900, color: text),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        elevation: 0,
        height: 72,
        indicatorColor:
            dark ? const Color(0xFF1E3A4A) : const Color(0xFFDDF4FF),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: text),
        ),
      ),
    );
  }
}