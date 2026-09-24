import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/widgets.dart';
import 'data/product_models.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'state/products_providers.dart';

/// TZ 11-bo'lim: Ombor — mahsulotlar ro'yxati, qidiruv, filtr va summary.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(productsControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Product? product}) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ProductFormScreen(product: product),
      ),
    );
    if (changed == true && mounted) {
      await ref.read(productsControllerProvider.notifier).load();
    }
  }

  Future<void> _openDetail(Product product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ProductDetailScreen(
          productId: product.id,
          initial: product,
        ),
      ),
    );
    // Kirim, chiqim, tahrirlash yoki o'chirishdan keyin ro'yxat yangilanadi.
    if (mounted) {
      await ref.read(productsControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ProductsListState state = ref.watch(productsControllerProvider);
    final ProductsController notifier =
        ref.read(productsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.navInventory)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.productAddTitle),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
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
            labels: s.productFilters,
            selectedIndex: state.filterIndex,
            onSelected: notifier.setFilter,
          ),
          // TZ 11: kategoriya bo'yicha filtr (GET /products/categories).
          if (state.categories.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            AppFilterChips(
              labels: <String>[s.filterAll, ...state.categories],
              selectedIndex: state.categoryIndex,
              onSelected: notifier.setCategory,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildBody(s, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppStrings s,
    ProductsListState state,
    ProductsController notifier,
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
        icon: Icons.inventory_2_outlined,
        title: s.productsEmptyTitle,
        message: s.productsEmptyBody,
        actionLabel: s.productAddTitle,
        onAction: () => _openForm(),
      );
    }

    final ProductsSummary? summary = state.summary;
    final bool showSummary = summary != null && !state.hasQuery;
    final int headerCount = showSummary ? 1 : 0;

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
        itemCount: state.items.length + headerCount,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          if (showSummary && index == 0) {
            return _InventorySummaryCard(summary: summary);
          }
          final Product product = state.items[index - headerCount];
          return _ProductTile(
            product: product,
            onTap: () => _openDetail(product),
          );
        },
      ),
    );
  }
}

/// Ombor umumiy holati: qiymat, mahsulotlar soni, kam qoldiq/tugagan.
class _InventorySummaryCard extends StatelessWidget {
  const _InventorySummaryCard({required this.summary});

  final ProductsSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(s.stockValueLabel, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          MoneyText(summary.stockValue, size: 22),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _SummaryBadge(
                label: s.productsCountText(summary.totalProducts),
                background: AppColors.lightGreen,
                foreground: AppColors.darkGreen,
              ),
              if (summary.lowStockCount > 0)
                _SummaryBadge(
                  label: '${s.filterLowStock}: ${summary.lowStockCount}',
                  background: AppColors.warningSurface,
                  foreground: AppColors.warning,
                ),
              if (summary.outOfStockCount > 0)
                _SummaryBadge(
                  label: '${s.filterOutOfStock}: ${summary.outOfStockCount}',
                  background: AppColors.dangerSurface,
                  foreground: AppColors.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final (Color statusBg, Color statusFg) = switch (product.stockStatus) {
      'out' => (AppColors.dangerSurface, AppColors.danger),
      'low' => (AppColors.warningSurface, AppColors.warning),
      _ => (AppColors.successSurface, AppColors.darkGreen),
    };

    final String subtitle = <String?>[product.category, product.unit]
        .whereType<String>()
        .join(' • ');

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: AppRadius.field,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: statusFg,
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
                if (subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              MoneyText(product.sellPrice, size: 15),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '${s.stockLabel}: ${formatQty(product.stock)} ${product.unit}',
                  style: textTheme.labelSmall?.copyWith(color: statusFg),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
