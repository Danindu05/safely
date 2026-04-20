import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.navy,
          secondary: AppColors.teal,
          tertiary: AppColors.info,
          surface: AppColors.surface,
          surfaceContainerHighest: AppColors.surfaceMuted,
          onSurface: AppColors.navyDeep,
          onSurfaceVariant: AppColors.muted,
          outlineVariant: AppColors.line,
          error: AppColors.emergency,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navyDeep,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: Color(0x80E4EAF1)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.tealSoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.navyDeep, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.navy,
        backgroundColor: AppColors.surfaceMuted,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.navyDeep,
        ),
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
          side: const BorderSide(color: AppColors.line),
          foregroundColor: AppColors.navyDeep,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navyDeep,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.teal;
          }
          return AppColors.line;
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.7,
        ),
        displaySmall: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 15,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: AppColors.navyDeep,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
