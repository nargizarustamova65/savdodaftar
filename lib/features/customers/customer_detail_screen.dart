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
import '../debts/debt_form_screen.dart';
import 'customer_form_screen.dart';
import 'customers_screen.dart' show CustomerAvatar;
import 'data/customer_models.dart';
import 'data/customers_repository.dart';
import 'state/customers_providers.dart';

/// TZ 10-bo'lim: mijoz profili — balans, amallar va tarix.
class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    this.initial,
  });

  final int customerId;

  /// Ro'yxatdan kelgan dastlabki ma'lumot — tarix yuklangunicha ko'rsatiladi.
  final Customer? initial;

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  Customer? _customer;
  List<CustomerHistoryItem> _items = <CustomerHistoryItem>[];
  bool _isLoading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _customer = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final CustomerHistory history = await ref
          .read(customersRepositoryProvider)
          .history(widget.customerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _customer = history.customer;
        _items = history.items;
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

  Future<void> _edit() async {
    final Customer? customer = _customer;
    if (customer == null) {
      return;
    }
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            CustomerFormScreen(customer: customer),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  Future<void> _delete() async {
    final AppStrings s = context.s;
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: s.deleteCustomerTitle,
      message: s.deleteCustomerBody,
      confirmLabel: s.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await ref
          .read(customersRepositoryProvider)
          .delete(widget.customerId);
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
    final Customer? customer = _customer;
    if (customer == null) {
      return;
    }

    final String? message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _PaymentSheet(customer: customer),
    );

    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await _load();
    }
  }

  Future<void> _addDebt() async {
    final Customer? customer = _customer;
    if (customer == null) {
      return;
    }
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => DebtFormScreen(customer: customer),
      ),
    );
    if (created == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final Customer? customer = _customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer?.name ?? ''),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'edit') {
                _edit();
              } else if (value == 'delete') {
                _delete();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text(s.edit)),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(
                  s.delete,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(s, customer),
    );
  }

  Widget _buildBody(AppStrings s, Customer? customer) {
    if (customer == null && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customer == null) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: s.errorNetwork,
        message: _error == null ? null : apiErrorText(s, _error!),
        actionLabel: s.retry,
        onAction: _load,
      );
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasDebt = customer.balance > 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: <Widget>[
          // —— Profil sarlavhasi: ism + telefon + balans (TZ 10)
          AppCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CustomerAvatar(name: customer.name, size: 56),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(customer.name, style: textTheme.titleMedium),
                          if (customer.phone != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              Phone.formatFull(customer.phone!),
                              style: textTheme.bodySmall,
                            ),
                          ],
                          if (customer.address != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              customer.address!,
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Text(
                      hasDebt ? s.customerDebtLabel : s.balanceLabel,
                      style: textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    MoneyText(
                      customer.balance,
                      size: 20,
                      color: hasDebt ? AppColors.danger : AppColors.primary,
                    ),
                  ],
                ),
                if ((customer.overdueDebtsCount ?? 0) > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _Badge(
                      label:
                          '${s.overdueLabel}: ${customer.overdueDebtsCount}',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // —— Asosiy amallar: +Qarz | To'lov (TZ 10)
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: s.quickDebt,
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  onPressed: _addDebt,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: s.quickPayment,
                  icon: Icons.payments_outlined,
                  size: AppButtonSize.medium,
                  onPressed: hasDebt ? _acceptPayment : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // —— Tarix: savdolar, qarzlar, to'lovlar (TZ 10)
          Text(s.historyTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (_isLoading && _items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            EmptyState(
              icon: Icons.history_rounded,
              title: s.historyEmptyTitle,
              message: s.historyEmptyBody,
            )
          else
            ...(_items.map(
              (CustomerHistoryItem item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _HistoryTile(item: item),
              ),
            )),
        ],
      ),
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final CustomerHistoryItem item;

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}, '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final (IconData icon, Color color, Color surface, String label) =
        switch (item.type) {
      HistoryType.debt => (
          Icons.north_east_rounded,
          AppColors.danger,
          AppColors.dangerSurface,
          s.historyDebt,
        ),
      HistoryType.payment => (
          Icons.south_west_rounded,
          AppColors.primary,
          AppColors.successSurface,
          s.historyPayment,
        ),
      _ => (
          Icons.shopping_bag_outlined,
          AppColors.info,
          AppColors.infoSurface,
          s.historySale,
        ),
    };

    final Widget amount = switch (item.type) {
      HistoryType.debt => MoneyText(
          item.amount,
          size: 15,
          signed: true,
          color: AppColors.danger,
        ),
      HistoryType.payment => MoneyText(
          -item.amount,
          size: 15,
          color: AppColors.primary,
        ),
      _ => MoneyText(item.amount, size: 15),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(label, style: textTheme.titleSmall),
                    if (item.type == HistoryType.debt && item.isOverdue) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      _Badge(label: s.overdueLabel),
                    ],
                  ],
                ),
                if (item.note != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    item.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 2),
                Text(_formatDate(item.date), style: textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          amount,
        ],
      ),
    );
  }
}

/// To'lov qabul qilish — TZ 27 "To'lov" oqimi:
/// Summa -> Usul (naqd/karta) -> Tasdiqlash.
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.customer});

  final Customer customer;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
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
    // Balansdan ortiq to'lovni qabul qilmaymiz (TZ 29).
    if (_amount > widget.customer.balance) {
      setState(
        () => _amountError =
            s.amountExceedsText(Money.format(widget.customer.balance)),
      );
      return;
    }

    setState(() {
      _amountError = null;
      _isBusy = true;
    });

    try {
      final CustomersRepository repository =
          ref.read(customersRepositoryProvider);
      final ({Customer customer, String message}) result =
          await repository.pay(
        widget.customer.id,
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
                  Text('${s.customerDebtLabel}: ', style: textTheme.bodySmall),
                  MoneyText(
                    widget.customer.balance,
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
