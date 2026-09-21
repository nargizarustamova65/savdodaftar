import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografika — TZ v3, 0-bo'lim.
///
/// Shrift: Inter (fallback: SF Pro / Roboto — google_fonts topilmasa
/// platformaning standart shriftiga tushadi).
abstract final class AppTypography {
  static TextStyle _style({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double height = 1.35,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextTheme build() {
    return TextTheme(
      // Screen title: 20–22px Bold
      headlineSmall: _style(size: 22, weight: FontWeight.w700, height: 1.25),
      titleLarge: _style(size: 20, weight: FontWeight.w700, height: 1.25),

      // Section title: 16–18px Semibold
      titleMedium: _style(size: 17, weight: FontWeight.w600),
      titleSmall: _style(size: 15, weight: FontWeight.w600),

      // Body: 14–16px Regular
      bodyLarge: _style(size: 16, weight: FontWeight.w400, height: 1.45),
      bodyMedium: _style(size: 14, weight: FontWeight.w400, height: 1.45),

      // Secondary text: 12–13px Regular
      bodySmall: _style(
        size: 13,
        weight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),

      // Button: 14–16px Semibold
      labelLarge: _style(size: 16, weight: FontWeight.w600, height: 1.2),
      labelMedium: _style(size: 14, weight: FontWeight.w600, height: 1.2),
      labelSmall: _style(
        size: 12,
        weight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.2,
      ),
    );
  }

  /// Pul summalari uchun — raqamlar bir xil kenglikda turadi.
  static TextStyle money({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}
