import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/widgets.dart';
import 'state/expenses_providers.dart';

/// TZ 14: xarajat qo'shish — Kategoriya -> Summa -> Sana -> Izoh -> Saqlash.
/// Muvaffaqiyatda `Navigator.pop(true)` qaytaradi.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final TextEditingController _noteController = TextEditingController();

  int? _categoryIndex;
  int _amount = 0;
  DateTime _spentAt = DateTime.now();
  String? _categoryError;
  String? _amountError;
  bool _isBusy = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  String _ymd(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _spentAt = picked);
    }
  }

  Future<void> _submit() async {
    final AppStrings s = context.s;

    setState(() {
      _categoryError =
          _categoryIndex == null ? s.validationCategoryRequired : null;
      _amountError = _amount <= 0 ? s.validationAmountInvalid : null;
    });
    if (_categoryError != null || _amountError != null) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      await ref.read(expensesRepositoryProvider).create(
            category: AppStrings.expenseCategoryKeys[_categoryIndex!],
            amount: _amount,
            note: _noteController.text,
            spentAt: _ymd(_spentAt),
          );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorText(context.s, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<String> categories = s.expenseCategories;

    return Scaffold(
      appBar: AppBar(title: Text(s.expenseAddTitle)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: <Widget>[
                  // —— Kategoriya (TZ 14: ijara, transport, maosh, ...)
                  Text(s.expenseCategoryLabel, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (int i = 0; i < categories.length; i++)
                        _CategoryChip(
                          label: categories[i],
                          selected: _categoryIndex == i,
                          onTap: () => setState(() {
                            _categoryIndex = i;
                            _categoryError = null;
                          }),
                        ),
                    ],
                  ),
                  if (_categoryError != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _categoryError!,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // —— Summa
                  MoneyInput(
                    label: s.amountLabel,
                    errorText: _amountError,
                    onChanged: (int value) {
                      _amount = value;
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // —— Sana
                  Text(s.dateLabel, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    onTap: _pickDate,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderColor: AppColors.border,
                    shadows: const <BoxShadow>[],
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.event_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _formatDate(_spentAt),
                            style: textTheme.titleSmall,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // —— Izoh
                  AppTextField(
                    label: s.noteLabel,
                    hint: s.noteHint,
                    controller: _noteController,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: AppButton(
                label: s.save,
                isLoading: _isBusy,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tanlanadigan kategoriya chipi — pill shakl, yashil aksent.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightGreen : AppColors.card,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.darkGreen : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
