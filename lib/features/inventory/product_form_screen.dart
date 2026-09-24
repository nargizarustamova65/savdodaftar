import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import 'data/product_models.dart';
import 'data/products_repository.dart';
import 'state/products_providers.dart';

/// TZ 12-bo'lim: mahsulot qo'shish/tahrirlash formasi — nomi, kategoriya,
/// barcode, birlik, tannarx, sotuv narxi, boshlang'ich va minimal qoldiq.
/// Marja avtomatik ko'rsatiladi. Muvaffaqiyatda `Navigator.pop(true)`.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});

  /// null — yangi mahsulot, aks holda tahrirlash.
  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;

  int _unitIndex = 0;
  int _buyPrice = 0;
  int _sellPrice = 0;

  String? _nameError;
  String? _sellPriceError;
  bool _isBusy = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final Product? product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _buyPriceController = TextEditingController(
      text: product == null || (product.buyPrice ?? 0) <= 0
          ? ''
          : Money.group(product.buyPrice!),
    );
    _sellPriceController = TextEditingController(
      text: product == null || product.sellPrice <= 0
          ? ''
          : Money.group(product.sellPrice),
    );
    _stockController = TextEditingController();
    _minStockController = TextEditingController(
      text: product == null || product.minStock <= 0
          ? ''
          : formatQty(product.minStock),
    );
    if (product != null) {
      _unitIndex =
          productUnits.indexOf(product.unit).clamp(0, productUnits.length - 1);
      _buyPrice = product.buyPrice?.round() ?? 0;
      _sellPrice = product.sellPrice.round();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppStrings s = context.s;
    final String name = _nameController.text.trim();
    final int sellPrice = Money.parse(_sellPriceController.text);

    setState(() {
      _nameError = name.isEmpty ? s.validationProductNameRequired : null;
      _sellPriceError = sellPrice <= 0 ? s.validationSellPriceRequired : null;
    });
    if (_nameError != null || _sellPriceError != null) {
      return;
    }

    final int buyPrice = Money.parse(_buyPriceController.text);
    final double? minStock = parseQty(_minStockController.text);

    setState(() => _isBusy = true);

    try {
      final ProductsRepository repository =
          ref.read(productsRepositoryProvider);
      if (_isEdit) {
        await repository.update(
          widget.product!.id,
          name: name,
          sellPrice: sellPrice,
          category: _categoryController.text,
          barcode: _barcodeController.text,
          unit: productUnits[_unitIndex],
          buyPrice: buyPrice > 0 ? buyPrice : null,
          minStock: minStock,
        );
      } else {
        await repository.create(
          name: name,
          sellPrice: sellPrice,
          category: _categoryController.text,
          barcode: _barcodeController.text,
          unit: productUnits[_unitIndex],
          buyPrice: buyPrice > 0 ? buyPrice : null,
          stock: parseQty(_stockController.text),
          minStock: minStock,
        );
      }

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
    final bool showMargin = _buyPrice > 0 && _sellPrice > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? s.productEditTitle : s.productAddTitle),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: <Widget>[
                  AppTextField(
                    label: s.productNameLabel,
                    hint: s.productNameHint,
                    controller: _nameController,
                    errorText: _nameError,
                    autofocus: !_isEdit,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.inventory_2_outlined,
                    onChanged: (String _) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.categoryLabel,
                    hint: s.categoryHint,
                    controller: _categoryController,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.category_outlined,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.barcodeLabel,
                    controller: _barcodeController,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.qr_code_rounded,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    s.unitLabel,
                    style: textTheme.titleSmall
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: List<Widget>.generate(
                      productUnits.length,
                      (int index) {
                        final bool selected = index == _unitIndex;
                        return ChoiceChip(
                          label: Text(productUnits[index]),
                          selected: selected,
                          onSelected: (bool _) =>
                              setState(() => _unitIndex = index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MoneyInput(
                    label: s.buyPriceLabel,
                    controller: _buyPriceController,
                    onChanged: (int value) =>
                        setState(() => _buyPrice = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MoneyInput(
                    label: s.sellPriceLabel,
                    controller: _sellPriceController,
                    errorText: _sellPriceError,
                    onChanged: (int value) => setState(() {
                      _sellPrice = value;
                      _sellPriceError = null;
                    }),
                  ),
                  // TZ 12: avtomatik marja va taxminiy foyda ko'rsatiladi.
                  if (showMargin) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: const BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: AppRadius.field,
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            '${s.marginLabel}: '
                            '${Money.marginPercent(buyPrice: _buyPrice, sellPrice: _sellPrice).toStringAsFixed(0)}%',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: AppColors.darkGreen),
                          ),
                          const Spacer(),
                          MoneyText(
                            _sellPrice - _buyPrice,
                            size: 14,
                            signed: true,
                            color: AppColors.darkGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Qoldiq faqat yaratishda kiritiladi — keyin kirim/chiqim orqali.
                  if (!_isEdit) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: s.initialStockLabel,
                      hint: '0',
                      controller: _stockController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.minStockLabel,
                    hint: '0',
                    controller: _minStockController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
