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
import 'product_form_screen.dart';
import 'state/products_providers.dart';
import 'stock_movement_sheet.dart';

/// TZ 11-bo'lim: mahsulot sahifasi — qoldiq, narxlar, marja,
/// kirim/chiqim tugmalari va harakatlar tarixi.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initial,
  });

  final int productId;

  /// Ro'yxatdan kelgan dastlabki ma'lumot — sahifa yuklangunicha ko'rsatiladi.
  final Product? initial;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  ApiException? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _product = widget.initial;
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final Product product =
          await ref.read(productsRepositoryProvider).fetch(widget.productId);
      if (!mounted) {
        return;
      }
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _openMovement({required bool isIncoming}) async {
    final Product? product = _product;
    if (product == null) {
      return;
    }
    final StockMovementResult? result =
        await showModalBottomSheet<StockMovementResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (BuildContext context) => StockMovementSheet(
        product: product,
        isIncoming: isIncoming,
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _product = result.product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    // Harakatlar ro'yxatini yangilash uchun qayta yuklaymiz.
    await _load();
  }

  /// TZ 21: inventarizatsiya — real qoldiq kiritiladi, farq avtomatik yoziladi.
  Future<void> _openAdjust() async {
    final Product? product = _product;
    if (product == null) {
      return;
    }
    final StockMovementResult? result =
        await showModalBottomSheet<StockMovementResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (BuildContext context) => StockAdjustSheet(product: product),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _product = result.product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    await _load();
  }

  Future<void> _edit() async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            ProductFormScreen(product: _product),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _delete() async {
    final AppStrings s = context.s;
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: s.deleteProductTitle,
      message: s.deleteProductBody,
      confirmLabel: s.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await ref.read(productsRepositoryProvider).delete(widget.productId);
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

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final Product? product = _product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product?.name ?? s.navInventory),
        actions: <Widget>[
          if (product != null)
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
      body: _buildBody(s, product),
    );
  }

  Widget _buildBody(AppStrings s, Product? product) {
    if (product == null) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: s.errorNetwork,
        message: _error == null ? s.errorUnknown : apiErrorText(s, _error!),
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
          _ProductHeaderCard(product: product),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: s.quickStockIn,
                  onPressed: () => _openMovement(isIncoming: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: s.stockOutTitle,
                  variant: AppButtonVariant.outline,
                  onPressed: () => _openMovement(isIncoming: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: s.adjustLabel,
            variant: AppButtonVariant.outline,
            onPressed: _openAdjust,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionTitle(title: s.movementsTitle),
          const SizedBox(height: AppSpacing.sm),
          if (product.movements.isEmpty)
            AppCard(
              child: Text(s.movementsEmptyTitle, style: textTheme.bodyMedium),
            )
          else
            ...product.movements.map(
              (StockMovementItem movement) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MovementTile(movement: movement, unit: product.unit),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductHeaderCard extends StatelessWidget {
  const _ProductHeaderCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final (Color statusBg, Color statusFg) = switch (product.stockStatus) {
      'out' => (AppColors.dangerSurface, AppColors.danger),
      'low' => (AppColors.warningSurface, AppColors.warning),
      _ => (AppColors.successSurface, AppColors.darkGreen),
    };

    final double? buyPrice = product.buyPrice;
    final double? margin = product.marginPercent ??
        (buyPrice != null && buyPrice > 0
            ? Money.marginPercent(
                buyPrice: buyPrice,
                sellPrice: product.sellPrice,
              )
            : null);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '${s.stockLabel}: ${formatQty(product.stock)} '
                  '${product.unit}',
                  style: textTheme.labelMedium?.copyWith(color: statusFg),
                ),
              ),
              const Spacer(),
              if (product.category != null)
                Text(product.category!, style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            label: s.sellPriceLabel,
            child: MoneyText(product.sellPrice, size: 15),
          ),
          if (buyPrice != null && buyPrice > 0)
            _InfoRow(
              label: s.buyPriceLabel,
              child: MoneyText(buyPrice, size: 15),
            ),
          if (margin != null)
            _InfoRow(
              label: s.marginLabel,
              child: Text(
                '${margin.toStringAsFixed(0)}%',
                style: textTheme.titleSmall
                    ?.copyWith(color: AppColors.darkGreen),
              ),
            ),
          _InfoRow(
            label: s.minStockLabel,
            child: Text(
              '${formatQty(product.minStock)} ${product.unit}',
              style: textTheme.titleSmall,
            ),
          ),
          if (product.stockValue != null)
            _InfoRow(
              label: s.stockValueLabel,
              child: MoneyText(product.stockValue!, size: 15),
            ),
          if (product.barcode != null)
            _InfoRow(
              label: s.barcodeLabel,
              child: Text(product.barcode!, style: textTheme.titleSmall),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: textTheme.bodySmall),
          const SizedBox(width: AppSpacing.md),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement, required this.unit});

  final StockMovementItem movement;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isIn = movement.isIncoming;
    final Color color = isIn ? AppColors.primary : AppColors.danger;

    final String subtitle = movement.note == null
        ? _formatDate(movement.createdAt)
        : '${_formatDate(movement.createdAt)} • ${movement.note}';

    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isIn ? AppColors.successSurface : AppColors.dangerSurface,
              borderRadius: AppRadius.field,
            ),
            child: Icon(
              isIn
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.movementTypeLabel(movement.type),
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${isIn ? '+' : '−'}${formatQty(movement.qty)} $unit',
                style: textTheme.titleSmall?.copyWith(color: color),
              ),
              const SizedBox(height: 2),
              Text(
                '${s.stockLabel}: ${formatQty(movement.stockAfter)}',
                style: textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}
