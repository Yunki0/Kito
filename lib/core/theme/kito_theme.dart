import 'package:flutter/material.dart';

import 'kito_colors.dart';
import 'kito_typography.dart';

abstract final class KitoTheme {
  static ThemeData get light => _build(dark: false);

  static ThemeData get dark => _build(dark: true);

  static ThemeData _build({required bool dark}) {
    final background = dark ? KitoColors.darkBackground : KitoColors.background;
    final surface = dark ? KitoColors.darkSurface : KitoColors.surface;
    final surfaceMuted = dark
        ? KitoColors.darkSurfaceMuted
        : KitoColors.surfaceMuted;
    final primary = dark ? KitoColors.darkPrimary : KitoColors.primary;
    final secondary = dark ? KitoColors.darkSecondary : KitoColors.secondary;
    final textPrimary = dark
        ? KitoColors.darkTextPrimary
        : KitoColors.textPrimary;
    final textSecondary = dark
        ? KitoColors.darkTextSecondary
        : KitoColors.textSecondary;
    final border = dark ? KitoColors.darkBorder : KitoColors.border;
    final error = dark ? KitoColors.darkError : KitoColors.error;
    final selectedGreen = dark
        ? KitoColors.darkSelectedGreen
        : KitoColors.selectedGreen;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: KitoColors.primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: background,
      error: error,
      tertiary: KitoColors.accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: KitoTypography.textTheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceMuted,
        indicatorColor: selectedGreen,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : textPrimary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: selectedGreen,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 46),
          foregroundColor: primary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
