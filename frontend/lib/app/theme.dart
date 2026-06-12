import 'package:flutter/material.dart';

import 'brand/brand_colors.dart';
import 'brand/brand_spacing.dart';

ThemeData buildZomiaTheme() {
  const pillRadius = 26.0;
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: BrandColors.orange,
        brightness: Brightness.light,
      ).copyWith(
        primary: BrandColors.orange,
        secondary: BrandColors.teal,
        tertiary: BrandColors.purple,
        error: BrandColors.error,
        surface: BrandColors.surface,
        onSurface: BrandColors.textPrimary,
      );

  return ThemeData(
    colorScheme: colorScheme,
    fontFamily: 'Sofia Sans',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: BrandColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: BrandColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: BrandColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: BrandColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: BrandColors.textPrimary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: BrandColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: BrandColors.textSecondary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: BrandColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Sofia Sans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: BrandColors.textSecondary,
      ),
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: BrandColors.background,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: BrandColors.background,
      foregroundColor: BrandColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: BrandColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
        side: const BorderSide(color: BrandColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pillRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pillRadius),
        borderSide: const BorderSide(color: BrandColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pillRadius),
        borderSide: const BorderSide(color: BrandColors.orange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pillRadius),
        borderSide: const BorderSide(color: BrandColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pillRadius),
        borderSide: const BorderSide(color: BrandColors.error, width: 2),
      ),
      filled: true,
      fillColor: BrandColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Sofia Sans',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandColors.orange,
        side: const BorderSide(color: BrandColors.orange, width: 1.2),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Sofia Sans',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
  );
}
