import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../customers/customers_screen.dart' show CustomerAvatar;
import '../inventory/data/product_models.dart' show formatQty;
import 'data/sale_models.dart';
import 'receipt_sheet.dart';
import 'state/sales_providers.dart';

/// TZ 6 va 16: savdo tafsiloti — mahsulotlar, to'lov taqsimoti va chek.
class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final int saleId;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  Sale? _sale;
  bool _isLoading = true;
  ApiException? _error;
  bool _receiptBusy = false;

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
      final Sale sale =
          await ref.read(salesRepositoryProvider).fetch(widget.saleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _sale = sale;
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

  Future<void> _showReceipt() async {
    setState(() => _receiptBusy = true);

    try {
      final SaleReceipt receipt =
          await ref.read(salesRepositoryProvider).receipt(widget.saleId);
      if (!mounted) {
        return;
      }
      setState(() => _receiptBusy = false);
      await showReceiptSheet(context, receipt);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _receiptBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorText(context.s, error))),
      );
    }
  }

  static String _formatDateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    return Scaffold(
      appBar: AppBar(title: Text(s.historySale)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: s.errorNetwork,
                  message: apiErrorText(s, _error!),
                  actionLabel: s.retry,
                  onAction: _load,
                )
              : _buildContent(s, _sale!),
    );
  }

  Widget _buildContent(AppStrings s, Sale sale) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: <Widget>[
        // —— Sarlavha: summa, holat va sana
        AppCard(
          child: Column(
            children: <Widget>[
              MoneyText(sale.total, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                s.saleStatusLabel(sale.status),
                style: textTheme.labelMedium?.copyWith(
                  color: sale.hasReturns
                      ? AppColors.danger
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                label: s.paymentMethodLabel,
                value: s.saleMethodLabel(sale.paymentMethod),
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                label: s.historyTitle,
                value: _formatDateTime(sale.soldAt),
              ),
            ],
          ),
        ),

        // —— Mijoz
        if (sale.customer != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                CustomerAvatar(name: sale.customer!.name, size: 36),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(s.customerLabel, style: textTheme.labelSmall),
                      Text(
                        sale.customer!.name,
                        style: textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // —— Mahsulotlar
        const SizedBox(height: AppSpacing.lg),
        SectionTitle(title: s.productsCountText(sale.items.length)),
        const SizedBox(height: AppSpacing.sm),
        for (final SaleItem item in sale.items) ...<Widget>[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatQty(item.qty)} ${item.unit} × '
                        '${Money.format(item.price)}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                MoneyText(item.total, size: 14),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // —— To'lov taqsimoti
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: <Widget>[
              if (sale.discount > 0) ...<Widget>[
                _MoneyRow(label: s.subtotalLabel, amount: sale.subtotal),
                const SizedBox(height: AppSpacing.xs),
                _MoneyRow(
                  label: s.discountOptionalLabel,
                  amount: -sale.discount,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (sale.paidCash > 0) ...<Widget>[
                _MoneyRow(label: s.payCash, amount: sale.paidCash),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (sale.paidCard > 0) ...<Widget>[
                _MoneyRow(label: s.payCard, amount: sale.paidCard),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (sale.debtAmount > 0) ...<Widget>[
                _MoneyRow(
                  label: s.payDebtLabel,
                  amount: sale.debtAmount,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (sale.hasReturns) ...<Widget>[
                _MoneyRow(
                  label: s.returnLabel,
                  amount: -sale.returnedTotal,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(s.totalLabel, style: textTheme.titleSmall),
                  MoneyText(sale.netTotal, size: 16),
                ],
              ),
            ],
          ),
        ),

        // —— Izoh
        if (sale.note != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.noteLabel, style: textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(sale.note!, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],

        // —— Chek (TZ 16)
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: s.receiptTitle,
          icon: Icons.receipt_long_rounded,
          variant: AppButtonVariant.secondary,
          isLoading: _receiptBusy,
          onPressed: _showReceipt,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: textTheme.bodySmall),
        Text(value, style: textTheme.labelMedium),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.amount,
    this.color,
  });

  final String label;
  final num amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: textTheme.bodySmall),
        MoneyText(
          amount,
          size: 14,
          color: color ?? AppColors.textPrimary,
        ),
      ],
    );
  }
}
