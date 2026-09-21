import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// PIN nuqtalari + raqamli klaviatura (TZ 7, 32, 33-bo'limlar).
///
/// Holat ota-widget'da saqlanadi: [value] joriy kiritilgan PIN,
/// [onChanged] har o'zgarishda, [onCompleted] to'liq kiritilganda chaqiriladi.
class PinInput extends StatelessWidget {
  const PinInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 4,
    this.onCompleted,
    this.hasError = false,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final bool enabled;

  void _append(String digit) {
    if (!enabled || value.length >= length) {
      return;
    }
    final String next = value + digit;
    onChanged(next);
    if (next.length == length) {
      onCompleted?.call(next);
    }
  }

  void _backspace() {
    if (!enabled || value.isEmpty) {
      return;
    }
    onChanged(value.substring(0, value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(length, (int index) {
            final bool filled = index < value.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (hasError ? AppColors.danger : AppColors.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: hasError ? AppColors.danger : AppColors.border,
                  width: 1.6,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        _Keypad(onDigit: _append, onBackspace: _backspace),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const List<List<String>> rows = <List<String>>[
      <String>['1', '2', '3'],
      <String>['4', '5', '6'],
      <String>['7', '8', '9'],
      <String>['', '0', 'back'],
    ];

    return Column(
      children: rows.map<Widget>((List<String> row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map<Widget>((String key) {
              if (key.isEmpty) {
                return const SizedBox(width: 88, height: 64);
              }
              if (key == 'back') {
                return _KeypadKey(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                );
              }
              return _KeypadKey(label: key, onTap: () => onDigit(key));
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 88,
      height: 64,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 24, color: AppColors.textSecondary)
                : Text(
                    label!,
                    style: textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
