import 'package:flutter/material.dart';

import 'brand/brand_colors.dart';
import 'brand/brand_spacing.dart';

ThemeData buildZomiaTheme() {
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
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
        borderSide: const BorderSide(color: BrandColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
        borderSide: const BorderSide(color: BrandColors.orange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
        borderSide: const BorderSide(color: BrandColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
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
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
