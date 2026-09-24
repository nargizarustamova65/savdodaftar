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

/// Kirim/chiqim natijasi — yangilangan mahsulot va backend xabari.
class StockMovementResult {
  const StockMovementResult({required this.product, required this.message});

  final Product product;
  final String message;
}

/// TZ 27 "Kirim" oqimi: mahsulotga kirim yoki chiqim kiritish bottom sheet.
/// Muvaffaqiyatda [StockMovementResult] bilan yopiladi.
class StockMovementSheet extends ConsumerStatefulWidget {
  const StockMovementSheet({
    super.key,
    required this.product,
    required this.isIncoming,
  });

  final Product product;

  /// true — kirim (stock-in), false — chiqim (stock-out).
  final bool isIncoming;

  @override
  ConsumerState<StockMovementSheet> createState() =>
      _StockMovementSheetState();
}

class _StockMovementSheetState extends ConsumerState<StockMovementSheet> {
  final TextEditingController _qtyController = TextEditingController();
  late final TextEditingController _buyPriceController;
  final TextEditingController _noteController = TextEditingController();

  bool _updateBuyPrice = false;
  String? _qtyError;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final double? buyPrice = widget.product.buyPrice;
    _buyPriceController = TextEditingController(
      text: buyPrice == null || buyPrice <= 0 ? '' : Money.group(buyPrice),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _buyPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppStrings s = context.s;
    final double? qty = parseQty(_qtyController.text);

    String? qtyError;
    if (qty == null || qty <= 0) {
      qtyError = s.validationAmountInvalid;
    } else if (!widget.isIncoming && qty > widget.product.stock) {
      // Chiqim mavjud qoldiqdan oshmasligi kerak.
      qtyError = s.amountExceedsText(
        '${formatQty(widget.product.stock)} ${widget.product.unit}',
      );
    }
    setState(() => _qtyError = qtyError);
    if (qtyError != null) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      final ProductsRepository repository =
          ref.read(productsRepositoryProvider);
      final ({Product product, String message}) result;
      if (widget.isIncoming) {
        final int buyPrice = Money.parse(_buyPriceController.text);
        result = await repository.stockIn(
          widget.product.id,
          qty: qty!,
          buyPrice: buyPrice > 0 ? buyPrice : null,
          updateBuyPrice: buyPrice > 0 && _updateBuyPrice,
          note: _noteController.text,
        );
      } else {
        result = await repository.stockOut(
          widget.product.id,
          qty: qty!,
          note: _noteController.text,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        StockMovementResult(product: result.product, message: result.message),
      );
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
    final Product product = widget.product;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.pill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.isIncoming ? s.quickStockIn : s.stockOutTitle,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${product.name} • ${s.stockLabel}: '
                '${formatQty(product.stock)} ${product.unit}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: s.qtyLabel,
                hint: '0',
                controller: _qtyController,
                errorText: _qtyError,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffix: Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.lg,
                    left: AppSpacing.sm,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      product.unit,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                onChanged: (String _) {
                  if (_qtyError != null) {
                    setState(() => _qtyError = null);
                  }
                },
              ),
              if (widget.isIncoming) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                MoneyInput(
                  label: s.buyPriceLabel,
                  controller: _buyPriceController,
                ),
                SwitchListTile.adaptive(
                  value: _updateBuyPrice,
                  onChanged: (bool value) =>
                      setState(() => _updateBuyPrice = value),
                  title: Text(s.updateBuyPriceLabel,
                      style: textTheme.bodyMedium),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: s.noteLabel,
                hint: s.noteHint,
                controller: _noteController,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: s.save,
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

/// TZ 21: inventarizatsiya bottom sheet — real (sanab chiqilgan) qoldiq
/// kiritiladi, kamomad/ortiqcha backend'da avtomatik hisoblanadi.
/// Muvaffaqiyatda [StockMovementResult] bilan yopiladi.
class StockAdjustSheet extends ConsumerStatefulWidget {
  const StockAdjustSheet({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends ConsumerState<StockAdjustSheet> {
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _stockError;
  bool _isBusy = false;

  @override
  void dispose() {
    _stockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppStrings s = context.s;
    final double? actualStock = parseQty(_stockController.text);

    // 0 ham to'g'ri qiymat — mahsulot butunlay tugagan bo'lishi mumkin.
    if (actualStock == null || actualStock < 0) {
      setState(() => _stockError = s.validationAmountInvalid);
      return;
    }

    setState(() {
      _stockError = null;
      _isBusy = true;
    });

    try {
      final ({Product product, String message}) result =
          await ref.read(productsRepositoryProvider).adjust(
                widget.product.id,
                actualStock: actualStock,
                note: _noteController.text,
              );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        StockMovementResult(product: result.product, message: result.message),
      );
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
    final Product product = widget.product;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.pill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(s.adjustLabel, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${product.name} • ${s.stockLabel}: '
                '${formatQty(product.stock)} ${product.unit}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: s.stockLabel,
                hint: formatQty(product.stock),
                controller: _stockController,
                errorText: _stockError,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffix: Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.lg,
                    left: AppSpacing.sm,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      product.unit,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                onChanged: (String _) {
                  if (_stockError != null) {
                    setState(() => _stockError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: s.noteLabel,
                hint: s.noteHint,
                controller: _noteController,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: s.save,
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

