import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_card.dart';

enum AlertTone { danger, warning, info, success }

/// Ogohlantirish kartasi — dashboard "E'tibor berish kerak" bloki va
/// bildirishnomalar ro'yxati uchun.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.message,
    required this.tone,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AlertTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final (Color accent, Color surface, IconData defaultIcon) = switch (tone) {
      AlertTone.danger => (
          AppColors.danger,
          AppColors.dangerSurface,
          Icons.error_outline_rounded,
        ),
      AlertTone.warning => (
          AppColors.warning,
          AppColors.warningSurface,
          Icons.warning_amber_rounded,
        ),
      AlertTone.info => (
          AppColors.info,
          AppColors.infoSurface,
          Icons.info_outline_rounded,
        ),
      AlertTone.success => (
          AppColors.success,
          AppColors.successSurface,
          Icons.check_circle_outline_rounded,
        ),
    };

    return AppCard(
      color: surface,
      shadows: const <BoxShadow>[],
      borderColor: accent.withOpacity(0.25),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon ?? defaultIcon, size: 22, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: textTheme.labelMedium?.copyWith(color: accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
