import 'package:flutter/material.dart';

/// BozorPro brend ranglari — TZ v3, 0-bo'lim (Global design system).
///
/// Uslub: oq fon, yashil akcent, minimalist SaaS ko'rinish.
abstract final class AppColors {
  /// Asosiy tugmalar, aktiv holatlar, brend.
  static const Color primary = Color(0xFF00A86B);

  /// Splash fon, bosilgan holat, sarlavha aksentlari.
  static const Color darkGreen = Color(0xFF006B45);

  /// Yengil fonlar, tanlangan chip, success card fon.
  static const Color lightGreen = Color(0xFFE9F8F1);

  /// Ekran foni.
  static const Color background = Color(0xFFF7F9FA);

  /// Kartalar, input fon.
  static const Color card = Color(0xFFFFFFFF);

  /// Asosiy matn.
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Ikkilamchi matn, placeholder.
  static const Color textSecondary = Color(0xFF7A828A);

  /// Qarz, xatolik, kam qoldiq.
  static const Color danger = Color(0xFFE53935);

  /// Ogohlantirish.
  static const Color warning = Color(0xFFF5A623);

  /// Ma'lumot, Telegram/SMS.
  static const Color info = Color(0xFF2F80ED);

  /// To'lov, tasdiq.
  static const Color success = Color(0xFF00A86B);

  /// Chegara chizig'i, input border.
  static const Color border = Color(0xFFE6EAED);

  // Status kartalari uchun yengil fonlar.
  static const Color dangerSurface = Color(0xFFFDECEA);
  static const Color warningSurface = Color(0xFFFFF6E5);
  static const Color infoSurface = Color(0xFFEAF2FE);
  static const Color successSurface = Color(0xFFE9F8F1);
}
