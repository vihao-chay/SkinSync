import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: AppColors.primary,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: AppColors.foreground,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.foreground,
          outline: AppColors.border,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'DMSans',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      textTheme: AppTextStyles.textTheme,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.08),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.heading,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.subtleText),
        labelStyle: const TextStyle(color: AppColors.mutedText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.85),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
      ),
      dividerColor: AppColors.border.withValues(alpha: 0.7),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface.withValues(alpha: 0.98),
        height: 74,
        elevation: 0,
        indicatorColor: AppColors.secondary,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : AppColors.mutedText;
          return IconThemeData(color: color, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedText,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ai,
        foregroundColor: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.beige,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: const TextStyle(color: AppColors.primaryDark),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkPanel,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'DMSans',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      visualDensity: VisualDensity.standard,
    ).copyWith(
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      cardColor: AppColors.surface,
      canvasColor: AppColors.surface,
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      hoverColor: AppColors.primary.withValues(alpha: 0.04),
      shadowColor: AppShadows.soft.first.color,
    );
  }
}
