import 'package:flutter/material.dart';

import '../shared/presentation/cafe_colors.dart';

ThemeData buildCafeTheme() {
  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: CafeColors.terracotta,
        brightness: Brightness.light,
      ).copyWith(
        primary: CafeColors.terracotta,
        onPrimary: Colors.white,
        primaryContainer: CafeColors.terracottaSoft,
        onPrimaryContainer: CafeColors.espresso,
        secondary: CafeColors.sage,
        onSecondary: Colors.white,
        secondaryContainer: CafeColors.sageSoft,
        onSecondaryContainer: CafeColors.espresso,
        tertiary: CafeColors.amber,
        surface: CafeColors.ivory,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: CafeColors.cream,
        surfaceContainer: CafeColors.sand,
        surfaceContainerHigh: CafeColors.warmGray,
        outline: CafeColors.outline,
        outlineVariant: CafeColors.outlineSoft,
      );

  final TextTheme textTheme = Typography.material2021().black.copyWith(
    displayMedium: const TextStyle(
      fontSize: 44,
      height: 1.05,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.1,
      color: CafeColors.espresso,
    ),
    headlineLarge: const TextStyle(
      fontSize: 30,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: CafeColors.espresso,
    ),
    headlineMedium: const TextStyle(
      fontSize: 25,
      height: 1.15,
      fontWeight: FontWeight.w700,
      color: CafeColors.espresso,
    ),
    headlineSmall: const TextStyle(
      fontSize: 21,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: CafeColors.espresso,
    ),
    titleLarge: const TextStyle(
      fontSize: 19,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: CafeColors.espresso,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: CafeColors.espresso,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      height: 1.4,
      color: CafeColors.ink,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      height: 1.4,
      color: CafeColors.ink,
    ),
    labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: textTheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: CafeColors.ivory,
    canvasColor: CafeColors.ivory,
    dividerTheme: const DividerThemeData(
      color: CafeColors.outlineSoft,
      space: 1,
      thickness: 1,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: CafeColors.outlineSoft),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CafeColors.ivory,
      foregroundColor: CafeColors.espresso,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: const BorderSide(color: CafeColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: CafeColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: CafeColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: CafeColors.terracotta, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: CafeColors.terracottaSoft,
      side: const BorderSide(color: CafeColors.outlineSoft),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(
        color: CafeColors.espresso,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: CafeColors.ivory,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CafeColors.espresso,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
