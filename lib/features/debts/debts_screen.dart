import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/widgets.dart';
import '../customers/customers_screen.dart' show CustomerAvatar;
import 'data/debt_models.dart';
import 'debt_detail_screen.dart';
import 'debt_form_screen.dart';
import 'state/debts_providers.dart';

/// TZ 7-bo'lim: qarz daftari — summary, qidiruv, filtr va ro'yxat.
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(debtsControllerProvider.notifier).load(),
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
        builder: (BuildContext context) => const DebtFormScreen(),
      ),
    );
    if (created == true && mounted) {
      await ref.read(debtsControllerProvider.notifier).load();
    }
  }

  Future<void> _openDetail(Debt debt) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            DebtDetailScreen(debtId: debt.id, initial: debt),
      ),
    );
    if (mounted) {
      await ref.read(debtsControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final DebtsListState state = ref.watch(debtsControllerProvider);
    final DebtsController notifier =
        ref.read(debtsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.navDebts)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.debtAddTitle),
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
            labels: s.debtFilters,
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
    DebtsListState state,
    DebtsController notifier,
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
        icon: Icons.account_balance_wallet_outlined,
        title: s.debtsEmptyTitle,
        message: s.debtsEmptyBody,
        actionLabel: s.debtAddTitle,
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
          final Debt debt = state.items[index];
          return _DebtTile(debt: debt, onTap: () => _openDetail(debt));
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final DebtsSummary summary;

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
                  Text(s.totalOutstanding, style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  MoneyText(summary.totalOutstanding, size: 16),
                  const SizedBox(height: 2),
                  Text(
                    s.debtorsCountText(summary.debtorsCount),
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
                  Text(s.overdueAmountLabel, style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  MoneyText(
                    summary.overdueAmount,
                    size: 16,
                    color: summary.overdueAmount > 0
                        ? AppColors.danger
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.overdueLabel}: ${summary.overdueCount}',
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

class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.debt, required this.onTap});

  final Debt debt;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String customerName = debt.customer?.name ?? '—';

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          CustomerAvatar(name: customerName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                if (debt.note != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    debt.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Text(
                      debt.dueDate == null
                          ? _formatDate(debt.issuedAt)
                          : '${s.dueDateShort}: ${_formatDate(debt.dueDate!)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: debt.isOverdue
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              MoneyText(
                debt.isPaid ? debt.amount : debt.remaining,
                size: 15,
                color: debt.isPaid
                    ? AppColors.textSecondary
                    : AppColors.danger,
              ),
              const SizedBox(height: 2),
              Text(
                debt.isOverdue
                    ? s.overdueLabel
                    : s.debtStatusLabel(debt.status),
                style: textTheme.labelSmall?.copyWith(
                  color: debt.isOverdue
                      ? AppColors.danger
                      : debt.isPaid
                          ? AppColors.primary
                          : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
