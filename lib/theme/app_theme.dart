import 'package:flutter/material.dart';

import 'app_colors.dart';

/// One place for the app's look and feel.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.primary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.overdue),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }

  /// Corner radius of the app's cards.
  static const double cardRadius = 20;

  /// Corner radius of the sheets and modals on Admire's screens.
  static const double sheetRadius = 32;

  /// The card used across the app. Figma draws cards as pure white with a
  /// generous corner radius and a soft shadow - no outline - which is what lets
  /// them float on the warm off-white page background.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F1C1B1B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      );

  /// The same card, but filled with a pastel colour. Admire's SLA and KPI cards
  /// are a solid tint rather than white-with-a-shadow, so they use this.
  static BoxDecoration pastelCard(Color fill) => BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(cardRadius),
      );
}
