import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

enum AppButtonVariant { primary, secondary, outline, danger, ghost }

enum AppButtonSize { large, medium }

/// Yagona tugma komponenti — TZ: katta va tushunarli, full-width.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double height = size == AppButtonSize.large ? 54 : 44;
    final TextStyle? textStyle =
        size == AppButtonSize.large ? textTheme.labelLarge : textTheme.labelMedium;

    final (Color background, Color foreground, Color? borderColor) = switch (variant) {
      AppButtonVariant.primary => (AppColors.primary, Colors.white, null),
      AppButtonVariant.secondary => (AppColors.lightGreen, AppColors.darkGreen, null),
      AppButtonVariant.danger => (AppColors.danger, Colors.white, null),
      AppButtonVariant.outline => (Colors.transparent, AppColors.textPrimary, AppColors.border),
      AppButtonVariant.ghost => (Colors.transparent, AppColors.primary, null),
    };

    final bool enabled = onPressed != null && !isLoading;
    final Color effectiveBackground =
        enabled ? background : background.withOpacity(0.45);
    final Color effectiveForeground =
        enabled ? foreground : foreground.withOpacity(0.45);

    final Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveForeground),
            ),
          )
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: effectiveForeground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle?.copyWith(color: effectiveForeground),
                ),
              ),
            ],
          );

    final Widget button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.field,
        border: borderColor == null
            ? null
            : Border.all(color: enabled ? borderColor : borderColor.withOpacity(0.45)),
      ),
      child: Material(
        color: effectiveBackground,
        borderRadius: AppRadius.field,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: content,
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
