import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme(Brightness brightness) {
  const seed = Color(0xFF0B6E4F);
  const secondary = Color(0xFFD98C3F);
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    primary: isDark ? const Color(0xFF66D3AE) : seed,
    secondary: isDark ? const Color(0xFFE7A154) : secondary,
  );

  final baseTextTheme = GoogleFonts.outfitTextTheme();
  final coloredTextTheme = baseTextTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
  final textTheme = coloredTextTheme.copyWith(
    displayLarge: coloredTextTheme.displayLarge?.copyWith(
      fontSize: 42,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    displayMedium: coloredTextTheme.displayMedium?.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.15,
    ),
    headlineMedium: coloredTextTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleLarge: coloredTextTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );

  final cardColor =
      isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface;
  final inputFill = isDark
      ? colorScheme.surfaceContainerHighest
      : colorScheme.surfaceContainerLowest;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.onSurface.withValues(alpha: 0.12),
      thickness: 1,
    ),
  );
}
