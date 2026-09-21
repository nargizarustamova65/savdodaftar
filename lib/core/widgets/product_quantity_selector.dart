import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// `− 2 +` miqdor tanlash — savdo va kirim ekranlari uchun.
class ProductQuantitySelector extends StatelessWidget {
  const ProductQuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 999999,
    this.step = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool canDecrease = value - step >= min;
    final bool canIncrease = value + step <= max;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.field,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            onTap: () => onChanged(value - step),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 56),
            alignment: Alignment.center,
            child: Text(value.toString(), style: textTheme.titleMedium),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            onTap: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.field,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 48,
          width: 48,
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
