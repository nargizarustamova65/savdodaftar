import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import 'data/sale_models.dart';
import 'sale_detail_screen.dart';
import 'sale_form_screen.dart';
import 'state/sales_providers.dart';

/// TZ 6 va 17: savdo tarixi — bugungi summary, qidiruv, filtr va ro'yxat.
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(salesControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const SaleFormScreen(),
      ),
    );
    if (created == true && mounted) {
      await ref.read(salesControllerProvider.notifier).load();
    }
  }

  Future<void> _openDetail(Sale sale) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            SaleDetailScreen(saleId: sale.id),
      ),
    );
    if (mounted) {
      await ref.read(salesControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final SalesListState state = ref.watch(salesControllerProvider);
    final SalesController notifier =
        ref.read(salesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.salesHistoryTitle)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.saleNewTitle),
      ),
      body: Column(
        children: <Widget>[
          if (state.summary != null) ...<Widget>[
            _SummaryCards(summary: state.summary!),
            const SizedBox(height: AppSpacing.md),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.md,
            ),
            child: SearchField(
              hint: s.searchHint,
              controller: _searchController,
              onChanged: notifier.setSearch,
            ),
          ),
          AppFilterChips(
            labels: s.saleFilters,
            selectedIndex: state.filterIndex,
            onSelected: notifier.setFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildBody(s, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppStrings s,
    SalesListState state,
    SalesController notifier,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: s.errorNetwork,
        message: apiErrorText(s, state.error!),
        actionLabel: s.retry,
        onAction: notifier.load,
      );
    }

    if (state.items.isEmpty) {
      if (state.hasQuery) {
        return EmptyState(
          icon: Icons.search_off_rounded,
          title: s.searchEmptyTitle,
          message: s.searchEmptyBody,
        );
      }
      return EmptyState(
        icon: Icons.shopping_basket_outlined,
        title: s.salesEmptyTitle,
        message: s.salesEmptyBody,
        actionLabel: s.saleNewTitle,
        onAction: _openForm,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: notifier.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          96,
        ),
        itemCount: state.items.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Sale sale = state.items[index];
          return _SaleTile(sale: sale, onTap: () => _openDetail(sale));
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final SalesSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        children: <Widget>[
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(s.statSales, style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  MoneyText(summary.netTotal, size: 16),
                  const SizedBox(height: 2),
                  Text(
                    s.salesCountText(summary.salesCount),
                    style: textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(s.statProfit, style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  MoneyText(
                    summary.profit,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.payCash}: ${Money.format(summary.cash)}',
                    style: textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale, required this.onTap});

  final Sale sale;
  final VoidCallback onTap;

  static String _formatDateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  IconData get _methodIcon {
    return switch (sale.paymentMethod) {
      'card' => Icons.credit_card_rounded,
      'debt' => Icons.account_balance_wallet_rounded,
      'mixed' => Icons.call_split_rounded,
      _ => Icons.payments_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int? itemsCount = sale.itemsCount ??
        (sale.items.isEmpty ? null : sale.items.length);
    final String title = sale.customer?.name ??
        (itemsCount == null
            ? s.historySale
            : s.productsCountText(itemsCount));

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(_methodIcon, size: 20, color: AppColors.darkGreen),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDateTime(sale.soldAt)} • '
                  '${s.saleMethodLabel(sale.paymentMethod)}',
                  style: textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              MoneyText(sale.netTotal, size: 15),
              if (sale.hasReturns) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  s.saleStatusLabel(sale.status),
                  style: textTheme.labelSmall
                      ?.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
