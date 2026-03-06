import 'package:flutter/material.dart';

/// Design tokens from React/Figma reference (theme.css).
class AppColors {
  AppColors._();

  /// Monochromatic palette (requested):
  /// - #E1ECF9 (light background)
  /// - #609CE1
  /// - #236AB9 (primary)
  /// - #133863
  /// - #091D34 (darkest)
  static const Color backgroundLight = Color(0xFFE1ECF9);
  static const Color backgroundDark = Color(0xFF091D34);

  static const Color foregroundLight = Color(0xFF091D34);
  static const Color foregroundDark = Color(0xFFE1ECF9);

  static const Color primary = Color(0xFF236AB9);
  static const Color primaryForeground = Color(0xFFE1ECF9);
  static const Color accent = Color(0xFF133863);

  static const Color secondary = Color(0xFF609CE1);
  static const Color secondaryForeground = Color(0xFFE1ECF9);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color destructive = Color(0xFF133863);

  /// Semantic colors (kept monochromatic).
  static const Color income = Color(0xFF609CE1);
  static const Color expense = Color(0xFF133863);
  static const Color transfer = Color(0xFF236AB9);

  static const Color borderLight = Color(0xFF609CE1);
  static const Color borderDark = Color(0xFF133863);
}

class AppTheme {
  AppTheme._();

  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;
  static const double radiusCard = 16;

  static ThemeData light({double fontSize = 16.0}) {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        surface: AppColors.surface,
        onSurface: AppColors.foregroundLight,
        error: AppColors.destructive,
        outline: AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.foregroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.foregroundLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundLight,
          side: const BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.foregroundLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: _textTheme(base.textTheme, fontSize),
    );
  }

  static ThemeData dark({double fontSize = 16.0}) {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.foregroundDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.foregroundDark,
        surface: AppColors.accent,
        onSurface: AppColors.foregroundDark,
        error: AppColors.destructive,
        outline: AppColors.borderDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.foregroundDark,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.foregroundDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.accent,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.foregroundDark,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.foregroundDark,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: _textTheme(base.textTheme, fontSize),
    );
  }

  static TextTheme _textTheme(TextTheme base, double fontSize) {
    final scale = fontSize / 16.0;
    return base.copyWith(
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: (base.bodyLarge?.fontSize ?? 16) * scale,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: (base.bodyMedium?.fontSize ?? 14) * scale,
        height: 1.5,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: (base.titleMedium?.fontSize ?? 16) * scale,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: (base.titleLarge?.fontSize ?? 22) * scale,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: (base.headlineSmall?.fontSize ?? 24) * scale,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
    );
  }
}
