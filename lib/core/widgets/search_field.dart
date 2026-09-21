import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Ro'yxat ekranlari uchun qidiruv maydoni.
/// [trailing] orqali barcode skaner yoki mikrofon tugmasi qo'shiladi.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.trailingIcon,
    this.onTrailingTap,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.field,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: textTheme.bodyMedium,
              cursorColor: AppColors.primary,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: hint,
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          if (trailingIcon != null)
            IconButton(
              onPressed: onTrailingTap,
              icon: Icon(trailingIcon, size: 22, color: AppColors.primary),
            )
          else
            const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
