import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_card.dart';
import 'money_text.dart';

/// Dashboard statistik kartasi: sarlavha + summa + ikon.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.caption,
    this.onTap,
  });

  final String title;
  final num amount;
  final IconData icon;
  final Color accentColor;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 32,
                width: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: AppRadius.field,
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MoneyText(amount, size: 18, color: accentColor),
          if (caption != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(caption!, style: textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}
