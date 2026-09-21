import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/widgets.dart';
import '../customers/customers_screen.dart' show CustomerAvatar;
import '../customers/data/customer_models.dart';
import '../customers/state/customers_providers.dart';
import 'state/debts_providers.dart';

/// TZ 7 va 27 "Qarz" oqimi: Mijoz -> Summa -> Muddat -> Saqlash.
/// Muvaffaqiyatda `Navigator.pop(true)` qaytaradi.
class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key, this.customer});

  /// Mijoz profilidan ochilganda oldindan tanlangan mijoz.
  final Customer? customer;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  final TextEditingController _noteController = TextEditingController();

  Customer? _customer;
  int _amount = 0;
  DateTime? _dueDate;
  String? _customerError;
  String? _amountError;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

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

  Future<void> _pickCustomer() async {
    final Customer? selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const _CustomerPickerSheet(),
    );
    if (selected != null) {
      setState(() {
        _customer = selected;
        _customerError = null;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    final AppStrings s = context.s;

    setState(() {
      _customerError =
          _customer == null ? s.validationCustomerRequired : null;
      _amountError = _amount <= 0 ? s.validationAmountInvalid : null;
    });
    if (_customerError != null || _amountError != null) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      await ref.read(debtsRepositoryProvider).create(
            customerId: _customer!.id,
            amount: _amount,
            note: _noteController.text,
            dueDate: _dueDate == null ? null : _ymd(_dueDate!),
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
    final Customer? customer = _customer;

    return Scaffold(
      appBar: AppBar(title: Text(s.debtAddTitle)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: <Widget>[
                  // —— Mijoz tanlash
                  Text(s.customerLabel, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    onTap: widget.customer == null ? _pickCustomer : null,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderColor: _customerError == null
                        ? AppColors.border
                        : AppColors.danger,
                    shadows: const <BoxShadow>[],
                    child: Row(
                      children: <Widget>[
                        if (customer == null)
                          const Icon(
                            Icons.person_search_rounded,
                            color: AppColors.textSecondary,
                          )
                        else
                          CustomerAvatar(name: customer.name, size: 36),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            customer?.name ?? s.selectCustomerTitle,
                            style: customer == null
                                ? textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  )
                                : textTheme.titleSmall,
                          ),
                        ),
                        if (widget.customer == null)
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ),
                  if (_customerError != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _customerError!,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // —— Summa
                  MoneyInput(
                    label: s.amountLabel,
                    autofocus: widget.customer != null,
                    errorText: _amountError,
                    onChanged: (int value) {
                      _amount = value;
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // —— Qaytarish muddati (TZ 7)
                  Text(s.dueDateOptionalLabel, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    onTap: _pickDueDate,
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
                            _dueDate == null
                                ? s.dueDateShort
                                : _formatDate(_dueDate!),
                            style: _dueDate == null
                                ? textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  )
                                : textTheme.titleSmall,
                          ),
                        ),
                        if (_dueDate != null)
                          TextButton(
                            onPressed: () => setState(() => _dueDate = null),
                            child: Text(
                              s.clearLabel,
                              style: textTheme.labelMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
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

/// Mijoz tanlash — qidiruvli bottom sheet.
class _CustomerPickerSheet extends ConsumerStatefulWidget {
  const _CustomerPickerSheet();

  @override
  ConsumerState<_CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  List<Customer> _all = <Customer>[];
  String _query = '';
  bool _isLoading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Customer> items =
          await ref.read(customersRepositoryProvider).list();
      if (!mounted) {
        return;
      }
      setState(() {
        _all = items;
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

  List<Customer> get _filtered {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _all;
    }
    return _all
        .where((Customer it) =>
            it.name.toLowerCase().contains(query) ||
            (it.phone ?? '').contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Customer> items = _filtered;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xl,
              AppSpacing.screen,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.selectCustomerTitle, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                SearchField(
                  hint: s.searchHint,
                  onChanged: (String value) =>
                      setState(() => _query = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: s.errorNetwork,
                        message: apiErrorText(s, _error!),
                        actionLabel: s.retry,
                        onAction: _load,
                      )
                    : items.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: s.searchEmptyTitle,
                            message: s.searchEmptyBody,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screen,
                              0,
                              AppSpacing.screen,
                              AppSpacing.xl,
                            ),
                            itemCount: items.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (BuildContext context, int index) {
                              final Customer customer = items[index];
                              return AppCard(
                                padding:
                                    const EdgeInsets.all(AppSpacing.md),
                                onTap: () =>
                                    Navigator.of(context).pop(customer),
                                child: Row(
                                  children: <Widget>[
                                    CustomerAvatar(
                                      name: customer.name,
                                      size: 36,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            customer.name,
                                            style: textTheme.titleSmall,
                                          ),
                                          if (customer.phone != null)
                                            Text(
                                              Phone.formatFull(
                                                customer.phone!,
                                              ),
                                              style: textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (customer.balance > 0)
                                      MoneyText(
                                        customer.balance,
                                        size: 13,
                                        color: AppColors.danger,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
