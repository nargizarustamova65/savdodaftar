import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/money.dart';
import 'app_text_field.dart';

/// Pul kiritish maydoni — yozayotganda avtomatik `150 000` formatlanadi.
/// [onChanged] butun summani qaytaradi.
class MoneyInput extends StatelessWidget {
  const MoneyInput({
    super.key,
    this.label,
    this.hint = '0',
    this.controller,
    this.errorText,
    this.helperText,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
  });

  final String? label;
  final String hint;
  final TextEditingController? controller;
  final String? errorText;
  final String? helperText;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      errorText: errorText,
      helperText: helperText,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[MoneyTextInputFormatter()],
      onChanged: (String value) => onChanged?.call(Money.parse(value)),
      suffix: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.lg, left: AppSpacing.sm),
        child: Center(
          child: Text(
            Money.currency,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Kiritilayotgan raqamlarni ming bo'yicha guruhlaydi.
class MoneyTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final String formatted = Money.group(Money.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
