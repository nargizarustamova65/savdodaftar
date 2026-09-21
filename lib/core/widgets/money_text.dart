import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/money.dart';

/// Pul summasini doim bir xil formatda ko'rsatadi: `150 000 so'm`.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.size = 16,
    this.weight = FontWeight.w700,
    this.color,
    this.withCurrency = true,
    this.signed = false,
    this.colorBySign = false,
  });

  final num amount;
  final double size;
  final FontWeight weight;
  final Color? color;
  final bool withCurrency;

  /// Musbat summa oldiga `+` qo'shadi (qarz tarixi uchun).
  final bool signed;

  /// true bo'lsa: musbat — yashil, manfiy — qizil.
  final bool colorBySign;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ??
        (colorBySign
            ? (amount < 0 ? AppColors.danger : AppColors.primary)
            : AppColors.textPrimary);

    return Text(
      Money.format(amount, withCurrency: withCurrency, signed: signed),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.money(
        size: size,
        weight: weight,
        color: effectiveColor,
      ),
    );
  }
}
