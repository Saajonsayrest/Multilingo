import 'package:flutter/material.dart';

/// Multilingo palette from the brand sheet. The names are old, the values are new:
/// teal = primary green, tomato = error red, olive = success green,
/// lemon = warning yellow, sky = info blue, gem = accent purple, mist = border.
class Palette {
  static const teal = Color(0xFF2E9D68);
  static const tealDark = Color(0xFF176B4A);
  static const tomato = Color(0xFFE85D63);
  static const tomatoDark = Color(0xFFC0454B);
  static const lemon = Color(0xFFF2B84B);
  static const lemonDark = Color(0xFFC98F1C);
  static const olive = Color(0xFF25A86A);
  static const oliveDark = Color(0xFF1B8553);
  static const sky = Color(0xFF4B8DE8);
  static const cream = Color(0xFFFFF9F0);
  static const ink = Color(0xFF26342D);
  static const mist = Color(0xFFE7EAE5);
  static const gem = Color(0xFF8875D8);
  static const primaryLight = Color(0xFFDDF6E7);
  static const textSecondary = Color(0xFF77847C);
  static const disabled = Color(0xFFD9DED9);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.teal,
    brightness: b,
    primary: dark ? const Color(0xFF52C48C) : Palette.teal,
    secondary: Palette.tomato,
    surface: dark ? const Color(0xFF141B21) : Palette.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xFF1D262E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: dark ? const Color(0xFF2B3742) : Palette.mist, width: 2),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF141B21) : Colors.white,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
