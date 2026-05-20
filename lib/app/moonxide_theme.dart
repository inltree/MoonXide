import 'package:flutter/material.dart';

class MoonXideTheme {
  static const Color snow = Color(0xFFF7FBFF);
  static const Color ice = Color(0xFFEAF6FF);
  static const Color frost = Color(0xFFD7ECFF);
  static const Color alpineBlue = Color(0xFF5BA7D8);
  static const Color deepBlue = Color(0xFF16496B);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: alpineBlue,
      brightness: Brightness.light,
      primary: const Color(0xFF2F8CCB),
      secondary: const Color(0xFF7BC7E8),
      surface: const Color(0xF8FFFFFF),
      surfaceContainerHighest: const Color(0xFFEFF8FF),
    );
    return _base(scheme).copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: snow,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white.withOpacity(0.72),
        foregroundColor: deepBlue,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x333B8FC7),
        titleTextStyle: const TextStyle(
          color: deepBlue,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: alpineBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF8ED8FF),
      secondary: const Color(0xFFB8E8FF),
      surface: const Color(0xFF0F2230),
      surfaceContainerHighest: const Color(0xFF1A3345),
    );
    return _base(scheme).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF071722),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xAA0F2230),
        foregroundColor: Color(0xFFE9F8FF),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surface.withOpacity(0.78),
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x293B8FC7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 4,
          shadowColor: const Color(0x553B8FC7),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: scheme.primary.withOpacity(0.32)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface.withOpacity(0.72),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.58), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface.withOpacity(0.82),
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withOpacity(0.14),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withOpacity(0.45), space: 24),
    );
  }
}
