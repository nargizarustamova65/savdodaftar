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
import '../customers/data/customer_models.dart';
import '../customers/state/customers_providers.dart';
import '../inventory/data/product_models.dart';
import '../inventory/state/products_providers.dart';
import 'data/sale_models.dart';
import 'data/sales_repository.dart';
import 'receipt_sheet.dart';
import 'state/sales_providers.dart';

/// TZ 6 va 27 "Savdo" oqimi:
/// Mahsulot -> Miqdor -> Savat -> To'lov -> Chek -> Tarix.
/// Muvaffaqiyatda `Navigator.pop(true)` qaytaradi.
class SaleFormScreen extends ConsumerStatefulWidget {
  const SaleFormScreen({super.key});

  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

/// Savatdagi bitta qator: ombordagi mahsulot yoki tezkor (nom + narx).
class _CartLine {
  _CartLine.product(Product p)
      : product = p,
        name = p.name,
        unit = p.unit,
        price = p.sellPrice.round();

  _CartLine.quick({required this.name, required this.price})
      : product = null,
        unit = 'dona';

  final Product? product;
  final String name;
  final String unit;
  final int price;
  int qty = 1;

  int get total => price * qty;
}

/// Tezkor mahsulot — omborda yo'q, faqat shu savdoda ishtirok etadi (TZ 6).
class _QuickItem {
  const _QuickItem({required this.name, required this.price});

  final String name;
  final int price;
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  final TextEditingController _noteController = TextEditingController();
  final List<_CartLine> _lines = <_CartLine>[];

  int _methodIndex = 0;
  Customer? _customer;
  DateTime? _dueDate;
  int _discount = 0;
  int _mixedCash = 0;
  int _mixedCard = 0;
  int _mixedDebt = 0;
  String? _itemsError;
  String? _customerError;
  String? _mixedError;
  bool _isBusy = false;

  String get _method => AppStrings.saleMethodKeys[_methodIndex];

  /// Savdoda qarz ishtirok etadimi — mijoz tanlash shart bo'ladi.
  bool get _hasDebtPart =>
      _method == 'debt' || (_method == 'mixed' && _mixedDebt > 0);

  int get _subtotal =>
      _lines.fold(0, (int sum, _CartLine line) => sum + line.total);

  int get _total {
    final int value = _subtotal - _discount;
    return value < 0 ? 0 : value;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _ymd(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  Future<void> _addProduct() async {
    final Object? picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const _ProductPickerSheet(),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _itemsError = null;
      if (picked is Product) {
        final int index = _lines.indexWhere(
          (_CartLine line) => line.product?.id == picked.id,
        );
        if (index >= 0) {
          // Miqdor ombor qoldig'idan oshib ketmasin (TZ 6).
          final int maxQty =
              picked.stock.floor() < 1 ? 1 : picked.stock.floor();
          if (_lines[index].qty < maxQty) {
            _lines[index].qty += 1;
          }
        } else {
          _lines.add(_CartLine.product(picked));
        }
      } else if (picked is _QuickItem) {
        _lines.add(_CartLine.quick(name: picked.name, price: picked.price));
      }
    });
  }

  Future<void> _pickCustomer() async {
    final Customer? selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const _CustomerPickerSheet(),
    );
    if (selected != null && mounted) {
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

    String? itemsError;
    String? customerError;
    String? mixedError;

    if (_lines.isEmpty) {
      itemsError = s.validationCartEmpty;
    }
    if (_hasDebtPart && _customer == null) {
      customerError = s.validationDebtCustomerRequired;
    }
    if (_method == 'mixed' &&
        _mixedCash + _mixedCard + _mixedDebt != _total) {
      mixedError = s.mixedMismatchText(Money.format(_total));
    }

    setState(() {
      _itemsError = itemsError;
      _customerError = customerError;
      _mixedError = mixedError;
    });
    if (itemsError != null || customerError != null || mixedError != null) {
      return;
    }

    setState(() => _isBusy = true);

    final List<Map<String, dynamic>> items = _lines
        .map(
          (_CartLine line) => <String, dynamic>{
            if (line.product != null)
              'product_id': line.product!.id
            else ...<String, dynamic>{
              'name': line.name,
              'unit': line.unit,
            },
            'qty': line.qty,
            'price': line.price,
          },
        )
        .toList();

    try {
      final SalesRepository repository = ref.read(salesRepositoryProvider);
      final ({Sale sale, String message}) result = await repository.create(
        paymentMethod: _method,
        items: items,
        customerId: _customer?.id,
        paidCash: _method == 'mixed' ? _mixedCash : null,
        paidCard: _method == 'mixed' ? _mixedCard : null,
        debtAmount: _method == 'mixed' ? _mixedDebt : null,
        dueDate: _hasDebtPart && _dueDate != null ? _ymd(_dueDate!) : null,
        discount: _discount > 0 ? _discount : null,
        note: _noteController.text,
      );

      // Chekni olishga urinamiz — xato bo'lsa savdo baribir saqlangan.
      SaleReceipt? receipt;
      try {
        receipt = await repository.receipt(result.sale.id);
      } on ApiException {
        receipt = null;
      }

      if (!mounted) {
        return;
      }
      if (result.message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
      if (receipt != null) {
        await showReceiptSheet(context, receipt);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
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
    final int mixedRemaining =
        _total - _mixedCash - _mixedCard - _mixedDebt;

    return Scaffold(
      appBar: AppBar(title: Text(s.saleNewTitle)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: <Widget>[
                  // —— Savat (TZ 6: mahsulot -> miqdor -> savat)
                  Text(s.cartTitle, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  for (int i = 0; i < _lines.length; i++) ...<Widget>[
                    _CartLineCard(
                      line: _lines[i],
                      onQtyChanged: (int qty) =>
                          setState(() => _lines[i].qty = qty),
                      onRemove: () => setState(() => _lines.removeAt(i)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  AppCard(
                    onTap: _addProduct,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderColor: _itemsError == null
                        ? AppColors.border
                        : AppColors.danger,
                    shadows: const <BoxShadow>[],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          s.addProductLabel,
                          style: textTheme.titleSmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  if (_itemsError != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _itemsError!,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // —— To'lov turi (TZ 6: Naqd | Karta | Qarz | Aralash)
                  Text(s.paymentMethodLabel, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  AppFilterChips(
                    labels: s.saleMethodLabels,
                    selectedIndex: _methodIndex,
                    padding: EdgeInsets.zero,
                    onSelected: (int index) => setState(() {
                      _methodIndex = index;
                      _mixedError = null;
                      _customerError = null;
                    }),
                  ),

                  // —— Aralash to'lov taqsimoti
                  if (_method == 'mixed') ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    MoneyInput(
                      label: s.payCash,
                      onChanged: (int value) => setState(() {
                        _mixedCash = value;
                        _mixedError = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MoneyInput(
                      label: s.payCard,
                      onChanged: (int value) => setState(() {
                        _mixedCard = value;
                        _mixedError = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MoneyInput(
                      label: s.payDebtLabel,
                      onChanged: (int value) => setState(() {
                        _mixedDebt = value;
                        _mixedError = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${s.remainingLabel}: ${Money.format(mixedRemaining)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: mixedRemaining == 0
                            ? AppColors.textSecondary
                            : AppColors.danger,
                      ),
                    ),
                    if (_mixedError != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _mixedError!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.danger),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // —— Mijoz (qarzga savdoda majburiy, boshqalarida ixtiyoriy)
                  Text(s.customerLabel, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    onTap: _pickCustomer,
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
                        if (customer != null)
                          IconButton(
                            onPressed: () =>
                                setState(() => _customer = null),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
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

                  // —— Qaytarish muddati (faqat qarz ishtirok etsa)
                  if (_hasDebtPart) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      s.dueDateOptionalLabel,
                      style: textTheme.titleSmall,
                    ),
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
                              onPressed: () =>
                                  setState(() => _dueDate = null),
                              child: Text(
                                s.clearLabel,
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // —— Chegirma va izoh
                  MoneyInput(
                    label: s.discountOptionalLabel,
                    onChanged: (int value) =>
                        setState(() => _discount = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.noteLabel,
                    hint: s.noteHint,
                    controller: _noteController,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // —— Jami va yakunlash (TZ 29: saqlashdan oldin qisqa preview)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_discount > 0) ...<Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(s.subtotalLabel, style: textTheme.bodySmall),
                        MoneyText(
                          _subtotal,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(s.totalLabel, style: textTheme.titleSmall),
                      MoneyText(_total, size: 20),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: s.completeSale,
                    isLoading: _isBusy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    required this.line,
    required this.onQtyChanged,
    required this.onRemove,
  });

  final _CartLine line;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Product? product = line.product;
    final int maxQty = product == null
        ? 999999
        : (product.stock.floor() < 1 ? 1 : product.stock.floor());

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.border,
      shadows: const <BoxShadow>[],
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Money.format(line.price)} × ${line.qty} ${line.unit}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ProductQuantitySelector(
                value: line.qty,
                max: maxQty,
                onChanged: onQtyChanged,
              ),
              MoneyText(line.total, size: 15),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mahsulot tanlash — qidiruvli bottom sheet + tezkor qo'shish (TZ 6).
class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  List<Product> _all = <Product>[];
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
      final List<Product> items =
          await ref.read(productsRepositoryProvider).list();
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

  List<Product> get _filtered {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _all;
    }
    return _all
        .where(
          (Product it) =>
              it.name.toLowerCase().contains(query) ||
              (it.barcode ?? '').toLowerCase().contains(query) ||
              (it.category ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _quickAdd() async {
    final _QuickItem? item = await showModalBottomSheet<_QuickItem>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const _QuickItemSheet(),
    );
    if (item != null && mounted) {
      Navigator.of(context).pop(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Product> items = _filtered;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
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
                Text(s.selectProductTitle, style: textTheme.titleMedium),
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
                              AppSpacing.md,
                            ),
                            itemCount: items.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(height: AppSpacing.sm),
                            itemBuilder:
                                (BuildContext context, int index) {
                              final Product product = items[index];
                              return _ProductTile(
                                product: product,
                                onTap: product.stock >= 1
                                    ? () => Navigator.of(context)
                                        .pop(product)
                                    : null,
                              );
                            },
                          ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: AppButton(
                label: s.quickAddProductTitle,
                icon: Icons.bolt_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: _quickAdd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: AppRadius.field,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.stockLabel}: ${formatQty(product.stock)} ${product.unit}',
                  style: textTheme.labelSmall?.copyWith(
                    color: product.isOut
                        ? AppColors.danger
                        : product.isLowStock
                            ? AppColors.warning
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          MoneyText(product.sellPrice, size: 14),
        ],
      ),
    );
  }
}

/// Tezkor mahsulot qo'shish — nom + narx (omborga yozilmaydi).
class _QuickItemSheet extends StatefulWidget {
  const _QuickItemSheet();

  @override
  State<_QuickItemSheet> createState() => _QuickItemSheetState();
}

class _QuickItemSheetState extends State<_QuickItemSheet> {
  final TextEditingController _nameController = TextEditingController();
  int _price = 0;
  String? _nameError;
  String? _priceError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final AppStrings s = context.s;
    final String name = _nameController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? s.validationProductNameRequired : null;
      _priceError = _price <= 0 ? s.validationSellPriceRequired : null;
    });
    if (_nameError != null || _priceError != null) {
      return;
    }

    Navigator.of(context).pop(_QuickItem(name: name, price: _price));
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
              Text(s.quickAddProductTitle, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: s.productNameLabel,
                hint: s.productNameHint,
                controller: _nameController,
                errorText: _nameError,
                autofocus: true,
                onChanged: (String value) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              MoneyInput(
                label: s.priceLabel,
                errorText: _priceError,
                onChanged: (int value) {
                  _price = value;
                  if (_priceError != null) {
                    setState(() => _priceError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(label: s.save, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mijoz tanlash — qidiruvli bottom sheet (qarzga/aralash savdo uchun).
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
        .where(
          (Customer it) =>
              it.name.toLowerCase().contains(query) ||
              (it.phone ?? '').contains(query),
        )
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
                            itemBuilder:
                                (BuildContext context, int index) {
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
