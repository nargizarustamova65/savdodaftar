import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/widgets.dart';
import 'state/reports_providers.dart';

/// TZ 17-bo'lim: hisobot va analitika — Bugun / 7 kun / 30 kun / Custom.
///
/// Ko'rsatkichlar: savdo, yalpi foyda, xarajat, sof foyda,
/// to'lov taqsimoti (naqd/karta/qarz), savdolar soni, o'rtacha chek.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(reportsControllerProvider.notifier).load(),
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  Future<void> _pickRange() async {
    final ReportsState state = ref.read(reportsControllerProvider);
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 3)),
      lastDate: now,
      initialDateRange:
          state.customFrom != null && state.customTo != null
              ? DateTimeRange(start: state.customFrom!, end: state.customTo!)
              : null,
    );
    if (picked != null) {
      ref
          .read(reportsControllerProvider.notifier)
          .setCustomRange(picked.start, picked.end);
    }
  }

  void _onPeriodSelected(int index) {
    final ReportsState state = ref.read(reportsControllerProvider);
    ref.read(reportsControllerProvider.notifier).setPeriod(index);
    if (index == 3 && (state.customFrom == null || state.customTo == null)) {
      _pickRange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ReportsState state = ref.watch(reportsControllerProvider);
    final ReportsController notifier =
        ref.read(reportsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.navReports)),
      body: Column(
        children: <Widget>[
          AppFilterChips(
            labels: s.reportPeriods,
            selectedIndex: state.periodIndex,
            onSelected: _onPeriodSelected,
          ),
          if (state.periodIndex == 3) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: AppCard(
                onTap: _pickRange,
                padding: const EdgeInsets.all(AppSpacing.md),
                borderColor: AppColors.border,
                shadows: const <BoxShadow>[],
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.date_range_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        state.customFrom == null || state.customTo == null
                            ? s.periodCustom
                            : '${_formatDate(state.customFrom!)} — '
                                '${_formatDate(state.customTo!)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
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
    ReportsState state,
    ReportsController notifier,
  ) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && !state.hasData) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: s.errorNetwork,
        message: apiErrorText(s, state.error!),
        actionLabel: s.retry,
        onAction: notifier.load,
      );
    }

    final double sales = state.sales?.netTotal ?? 0;
    final double profit = state.sales?.profit ?? 0;
    final double expense = state.expenses?.total ?? 0;
    final double netProfit = state.netProfit;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: notifier.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xxxl,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                  title: s.historySale,
                  amount: sales,
                  icon: Icons.shopping_cart_rounded,
                  caption: s.salesCountText(state.sales?.salesCount ?? 0),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  title: s.grossProfitLabel,
                  amount: profit,
                  icon: Icons.trending_up_rounded,
                  accentColor: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                  title: s.navExpenses,
                  amount: expense,
                  icon: Icons.receipt_long_rounded,
                  accentColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  title: s.netProfitLabel,
                  amount: netProfit,
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor:
                      netProfit < 0 ? AppColors.danger : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // —— To'lov taqsimoti: naqd / karta / qarzga (TZ 17 "Bugun")
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.paymentMethodLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                _AmountRow(label: s.payCash, amount: state.sales?.cash ?? 0),
                const SizedBox(height: AppSpacing.sm),
                _AmountRow(label: s.payCard, amount: state.sales?.card ?? 0),
                const SizedBox(height: AppSpacing.sm),
                _AmountRow(
                  label: s.payDebtLabel,
                  amount: state.sales?.debt ?? 0,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // —— Qo'shimcha ko'rsatkichlar
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _AmountRow(
                  label: s.averageCheckLabel,
                  amount: state.sales?.averageCheck ?? 0,
                ),
                if ((state.sales?.returnedTotal ?? 0) > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  _AmountRow(
                    label: s.returnLabel,
                    amount: state.sales?.returnedTotal ?? 0,
                    color: AppColors.danger,
                  ),
                ],
                if ((state.sales?.discount ?? 0) > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  _AmountRow(
                    label: s.discountOptionalLabel,
                    amount: state.sales?.discount ?? 0,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        MoneyText(amount, size: 14, color: color),
      ],
    );
  }
}
