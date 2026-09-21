import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/money.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/widgets.dart';
import '../customers/customers_screen.dart' show CustomerAvatar;
import 'data/debt_models.dart';
import 'data/debts_repository.dart';
import 'state/debts_providers.dart';

/// TZ 7-bo'lim: qarz detali — qoldiq, to'lovlar tarixi, to'lov qabul qilish.
class DebtDetailScreen extends ConsumerStatefulWidget {
  const DebtDetailScreen({super.key, required this.debtId, this.initial});

  final int debtId;
  final Debt? initial;

  @override
  ConsumerState<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends ConsumerState<DebtDetailScreen> {
  Debt? _debt;
  bool _isLoading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _debt = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Debt debt =
          await ref.read(debtsRepositoryProvider).fetch(widget.debtId);
      if (!mounted) {
        return;
      }
      setState(() {
        _debt = debt;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error;
      });
    }
  }

  Future<void> _delete() async {
    final AppStrings s = context.s;
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: s.deleteDebtTitle,
      message: s.deleteDebtBody,
      confirmLabel: s.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await ref.read(debtsRepositoryProvider).delete(widget.debtId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorText(context.s, error))),
      );
    }
  }

  Future<void> _acceptPayment() async {
    final Debt? debt = _debt;
    if (debt == null) {
      return;
    }

    final String? message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _DebtPaymentSheet(debt: debt),
    );

    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await _load();
    }
  }

  String _formatDate(DateTime date, {bool withTime = false}) {
    String two(int value) => value.toString().padLeft(2, '0');
    final String day = '${two(date.day)}.${two(date.month)}.${date.year}';
    if (!withTime) {
      return day;
    }
    return '$day, ${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final Debt? debt = _debt;

    return Scaffold(
      appBar: AppBar(
        title: Text(debt?.customer?.name ?? s.historyDebt),
        actions: <Widget>[
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
          ),
        ],
      ),
      body: _buildBody(s, debt),
    );
  }

  Widget _buildBody(AppStrings s, Debt? debt) {
    if (debt == null && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (debt == null) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: s.errorNetwork,
        message: _error == null ? null : apiErrorText(s, _error!),
        actionLabel: s.retry,
        onAction: _load,
      );
    }

    final TextTheme textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: <Widget>[
          AppCard(
            child: Column(
              children: <Widget>[
                if (debt.customer != null) ...<Widget>[
                  Row(
                    children: <Widget>[
                      CustomerAvatar(name: debt.customer!.name, size: 44),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              debt.customer!.name,
                              style: textTheme.titleSmall,
                            ),
                            if (debt.customer!.phone != null)
                              Text(
                                Phone.formatFull(debt.customer!.phone!),
                                style: textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      if (debt.isOverdue)
                        _Badge(label: s.overdueLabel)
                      else
                        Text(
                          s.debtStatusLabel(debt.status),
                          style: textTheme.labelSmall?.copyWith(
                            color: debt.isPaid
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _row(
                  textTheme,
                  s.amountLabel,
                  MoneyText(debt.amount, size: 15),
                ),
                const SizedBox(height: AppSpacing.md),
                _row(
                  textTheme,
                  s.paidLabel,
                  MoneyText(
                    debt.paidAmount,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _row(
                  textTheme,
                  s.remainingLabel,
                  MoneyText(
                    debt.remaining,
                    size: 18,
                    color:
                        debt.isPaid ? AppColors.primary : AppColors.danger,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _row(
                  textTheme,
                  s.dueDateShort,
                  Text(
                    debt.dueDate == null
                        ? '—'
                        : _formatDate(debt.dueDate!),
                    style: textTheme.titleSmall?.copyWith(
                      color: debt.isOverdue
                          ? AppColors.danger
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (debt.note != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _row(
                    textTheme,
                    s.noteLabel,
                    Flexible(
                      child: Text(
                        debt.note!,
                        textAlign: TextAlign.end,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: s.quickPayment,
            icon: Icons.payments_outlined,
            onPressed: debt.remaining > 0 ? _acceptPayment : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(s.paymentsTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (debt.payments.isEmpty)
            EmptyState(
              icon: Icons.payments_outlined,
              title: s.paymentsEmptyTitle,
            )
          else
            ...debt.payments.map(
              (DebtPayment payment) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: <Widget>[
                      Container(
                        height: 36,
                        width: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.successSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.south_west_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              payment.paymentMethod == 'card'
                                  ? s.payCard
                                  : s.payCash,
                              style: textTheme.titleSmall,
                            ),
                            Text(
                              _formatDate(payment.paidAt, withTime: true),
                              style: textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      MoneyText(
                        -payment.amount,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(TextTheme textTheme, String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: textTheme.bodyMedium),
        value,
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.danger),
      ),
    );
  }
}

/// Qarz bo'yicha to'lov qabul qilish — TZ 27 "To'lov" oqimi.
class _DebtPaymentSheet extends ConsumerStatefulWidget {
  const _DebtPaymentSheet({required this.debt});

  final Debt debt;

  @override
  ConsumerState<_DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends ConsumerState<_DebtPaymentSheet> {
  static const List<String> _methodKeys = <String>['cash', 'card'];

  final TextEditingController _noteController = TextEditingController();
  int _amount = 0;
  int _methodIndex = 0;
  String? _amountError;
  bool _isBusy = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppStrings s = context.s;

    if (_amount <= 0) {
      setState(() => _amountError = s.validationAmountInvalid);
      return;
    }
    // Qoldiqdan ortiq to'lovni qabul qilmaymiz (TZ 29).
    if (_amount > widget.debt.remaining) {
      setState(
        () => _amountError =
            s.amountExceedsText(Money.format(widget.debt.remaining)),
      );
      return;
    }

    setState(() {
      _amountError = null;
      _isBusy = true;
    });

    try {
      final DebtsRepository repository = ref.read(debtsRepositoryProvider);
      final ({Debt debt, String message}) result = await repository.pay(
        widget.debt.id,
        amount: _amount,
        method: _methodKeys[_methodIndex],
        note: _noteController.text,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result.message);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _amountError = apiErrorText(context.s, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(s.acceptPaymentTitle, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Text('${s.remainingLabel}: ', style: textTheme.bodySmall),
                  MoneyText(
                    widget.debt.remaining,
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              MoneyInput(
                label: s.amountLabel,
                autofocus: true,
                errorText: _amountError,
                onChanged: (int value) {
                  _amount = value;
                  if (_amountError != null) {
                    setState(() => _amountError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppFilterChips(
                labels: s.payMethods,
                selectedIndex: _methodIndex,
                padding: EdgeInsets.zero,
                onSelected: (int index) =>
                    setState(() => _methodIndex = index),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: s.noteLabel,
                hint: s.noteHint,
                controller: _noteController,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: s.confirm,
                isLoading: _isBusy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
