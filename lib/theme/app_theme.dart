import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ---------- LIGHT SCHEME COLORS (warm, inviting tones) ----------
  static const _lightPrimary = Color(
    0xFF069494,
  ); // Keep teal as primary (brand consistency)
  static const _lightOnPrimary = Color(0xFFFFFFFF);
  static const _lightSecondary = Color(0xFFEBAA26); // Warm yellow
  static const _lightOnSecondary = Color(0xFFFFFFFF);
  static const _lightTertiary = Color(
    0xFFEBAA26,
  ); // Warm brown/terracotta instead of cool purple
  static const _lightOnTertiary = Color(0xFFFFFFFF);
  static const _lightError = Color(0xFFC8433A); // Warmer red (less blue)
  static const _lightOnError = Color(0xFFFFFFFF);
  // Warm backgrounds: cream/ivory tones instead of cool grays
  static const _lightSurface = Color(0xFFFFF9F0); // Warm cream/ivory background
  static const _lightOnSurface = Color(0xFF2A2820); // Warm dark brown for text
  // Cards should be warmer than background but still distinct
  static const _lightSurfaceVariant = Color(0xFFFFF5E6); // Warmer cream variant
  static const _lightOnSurfaceVar = Color(0xFF3D382E); // Warm brown-gray text
  static const _lightOutline = Color(0xFF8B7D6B); // Warm brown-gray outline
  static const _lightOutlineVar = Color(
    0xFFD4C4B0,
  ); // Warm beige outline variant
  static const _lightInverseSurface = Color(
    0xFF3D382E,
  ); // Warm dark for inverse
  static const _lightOnInverseSurf = Color(
    0xFFFFF9F0,
  ); // Cream for text on inverse
  static const _lightInversePrimary = Color(0xFFB0E8E8); // Light warm teal
  static const _lightScrim = Colors.black;

  // ---------- DARK SCHEME COLORS ----------
  static const _darkPrimary = Color(0xFF069494);
  static const _darkOnPrimary = Color(0xFF121212);
  static const _darkSecondary = Color(0xFFEBAA26);
  static const _darkOnSecondary = Color(0xFF332D41);
  static const _darkTertiary = Color(0xFFEBAA26);
  static const _darkOnTertiary = Color(0xFF492532);
  static const _darkError = Color(0xFFC8433A);
  static const _darkOnError = Color(0xFF601410);
  static const _darkSurface = Color(0xFF121212);
  static const _darkOnSurface = Color(0xFFF1F1F1);
  static const _darkSurfaceVariant = Color(0xFF212121);
  static const _darkOnSurfaceVar = Color(0xFFCAC4D0);
  static const _darkOutline = Color(0xFF938F99);
  static const _darkOutlineVar = Color(0xFF49454F);
  static const _darkInverseSurface = Color(0xFFE6E1E5);
  static const _darkOnInverseSurf = Color(0xFF313033);
  static const _darkInversePrimary = Color(0xFF6750A4);
  static const _darkScrim = Colors.black;

  // Public themes
  static ThemeData light = _themeFromScheme(_lightScheme);
  static ThemeData dark = _themeFromScheme(_darkScheme);

  // Build explicit schemes
  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _lightPrimary,
    onPrimary: _lightOnPrimary,
    secondary: _lightSecondary,
    onSecondary: _lightOnSecondary,
    tertiary: _lightTertiary,
    onTertiary: _lightOnTertiary,
    error: _lightError,
    onError: _lightOnError,
    surface: _lightSurface,
    onSurface: _lightOnSurface,
    // Optional extras that many M3 widgets use:
    surfaceContainerHighest: _lightSurfaceVariant,
    onSurfaceVariant: _lightOnSurfaceVar,
    outline: _lightOutline,
    outlineVariant: _lightOutlineVar,
    inverseSurface: _lightInverseSurface,
    onInverseSurface: _lightOnInverseSurf,
    inversePrimary: _lightInversePrimary,
    scrim: _lightScrim,
  );

  static final ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _darkPrimary,
    onPrimary: _darkOnPrimary,
    secondary: _darkSecondary,
    onSecondary: _darkOnSecondary,
    tertiary: _darkTertiary,
    onTertiary: _darkOnTertiary,
    error: _darkError,
    onError: _darkOnError,
    surface: _darkSurface,
    onSurface: _darkOnSurface,
    surfaceContainerHighest: _darkSurfaceVariant,
    onSurfaceVariant: _darkOnSurfaceVar,
    outline: _darkOutline,
    outlineVariant: _darkOutlineVar,
    inverseSurface: _darkInverseSurface,
    onInverseSurface: _darkOnInverseSurf,
    inversePrimary: _darkInversePrimary,
    scrim: _darkScrim,
  );

  // Turn any ColorScheme into a ThemeData and tweak common components
  static ThemeData _themeFromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // App bar on a surface
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),

      // NavigationBar (bottom)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.leagueSpartan(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.leagueSpartan(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.leagueSpartan(fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // Typography: Spartan for headings, Roboto Mono for body/smaller text
      textTheme: _buildTextTheme(scheme, isDark),

      // Cards/surfaces - warmer cards in light mode
      cardTheme: CardThemeData(
        color: isDark
            ? scheme.surfaceContainerHighest
            : const Color(
                0xFFFFFDF8,
              ), // Warm off-white cards (cream with slight pink undertone)
        elevation: isDark ? 3 : 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide.none
              : BorderSide(
                  color: scheme.outline.withValues(alpha: 0.15),
                  width: 1,
                ), // Subtle warm border in light mode
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme, bool isDark) {
    final base = (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;

    // Headings -> Spartan
    final headings = GoogleFonts.leagueSpartanTextTheme(base).copyWith(
      displayLarge: GoogleFonts.leagueSpartan(
        textStyle: base.displayLarge,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.leagueSpartan(
        textStyle: base.displayMedium,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.leagueSpartan(
        textStyle: base.displaySmall,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.leagueSpartan(
        textStyle: base.headlineLarge,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.leagueSpartan(
        textStyle: base.headlineMedium,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.leagueSpartan(
        textStyle: base.headlineSmall,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.leagueSpartan(
        textStyle: base.titleLarge,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.leagueSpartan(
        textStyle: base.titleMedium,
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.leagueSpartan(
        textStyle: base.titleSmall,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );

    // Body/smaller -> Roboto Mono (reduced font sizes to prevent overflow)
    final robotoMono = GoogleFonts.robotoMonoTextTheme(base).copyWith(
      bodyLarge: GoogleFonts.robotoMono(
        textStyle: base.bodyLarge?.copyWith(fontSize: 14),
        color: scheme.onSurface,
      ),
      bodyMedium: GoogleFonts.robotoMono(
        textStyle: base.bodyMedium?.copyWith(fontSize: 12),
        color: scheme.onSurface,
      ),
      bodySmall: GoogleFonts.robotoMono(
        textStyle: base.bodySmall?.copyWith(fontSize: 10),
        color: scheme.onSurface,
      ),
      labelLarge: GoogleFonts.robotoMono(
        textStyle: base.labelLarge?.copyWith(fontSize: 12),
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.robotoMono(
        textStyle: base.labelMedium?.copyWith(fontSize: 10),
        color: scheme.onSurface,
      ),
      labelSmall: GoogleFonts.robotoMono(
        textStyle: base.labelSmall?.copyWith(fontSize: 8),
        color: scheme.onSurface,
      ),
    );

    // Merge: prefer Spartan for heading/title styles, Roboto Mono for body/labels.
    return headings.copyWith(
      bodyLarge: robotoMono.bodyLarge,
      bodyMedium: robotoMono.bodyMedium,
      bodySmall: robotoMono.bodySmall,
      labelLarge: robotoMono.labelLarge,
      labelMedium: robotoMono.labelMedium,
      labelSmall: robotoMono.labelSmall,
    );
  }
}
