import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_button.dart';

/// Moliyaviy va xavfli amallarni tasdiqlash oynasi — TZ 23 va 29-bo'limlar.
abstract final class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final AppStrings s = context.s;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextTheme textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.xxl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: textTheme.titleMedium),
                if (message != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(message, style: textTheme.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppButton(
                        label: cancelLabel ?? s.cancel,
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.medium,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: confirmLabel ?? s.confirm,
                        variant: destructive
                            ? AppButtonVariant.danger
                            : AppButtonVariant.primary,
                        size: AppButtonSize.medium,
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }
}
