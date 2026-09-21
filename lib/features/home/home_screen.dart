import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../auth/state/auth_providers.dart';
import '../debts/debt_form_screen.dart';
import '../debts/debts_screen.dart';
import '../expenses/expenses_screen.dart';
import '../inventory/inventory_screen.dart';
import '../sales/sale_form_screen.dart';
import 'state/home_providers.dart';

/// TZ 5-bo'lim: Dashboard — real API summary'lari bilan.
///
/// Quick action'lar: +Savdo, +Qarz, +To'lov (qarzlar), +Kirim (ombor).
/// Har bir ochilgan ekrandan qaytganda dashboard qayta yuklanadi.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(homeControllerProvider.notifier).load(),
    );
  }

  Future<void> _reload() => ref.read(homeControllerProvider.notifier).load();

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(builder: (BuildContext context) => screen),
    );
    if (mounted) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final HomeDashboardState state = ref.watch(homeControllerProvider);
    final String userName = ref.watch(authControllerProvider).user?.name ?? '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _buildBody(s, state, userName),
      ),
    );
  }

  Widget _buildBody(AppStrings s, HomeDashboardState state, String userName) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && !state.hasData) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: s.errorNetwork,
        message: apiErrorText(s, state.error!),
        actionLabel: s.retry,
        onAction: _reload,
      );
    }

    final double sales = state.sales?.netTotal ?? 0;
    final double profit = state.sales?.profit ?? 0;
    final double debtGiven = state.debts?.givenToday ?? 0;
    final double debtReturned = state.debts?.returnedToday ?? 0;
    final double expense = state.expenses?.total ?? 0;
    final int overdueCount = state.debts?.overdueCount ?? 0;
    final int lowStockCount = state.products?.attentionCount ?? 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: <Widget>[
          _Header(userName: userName),
          const SizedBox(height: AppSpacing.lg),
          const _ProBanner(),
          const SizedBox(height: AppSpacing.lg),
          _StatGrid(
            sales: sales,
            profit: profit,
            debtGiven: debtGiven,
            debtReturned: debtReturned,
          ),
          const SizedBox(height: AppSpacing.xl),
          _QuickActions(onOpen: _push),
          if (overdueCount > 0 || lowStockCount > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: SectionTitle(title: s.attentionNeeded),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Column(
                children: <Widget>[
                  if (overdueCount > 0)
                    AlertCard(
                      message: s.overdueDebts(overdueCount),
                      tone: AlertTone.danger,
                      actionLabel: s.view,
                      onAction: () => _push(const DebtsScreen()),
                    ),
                  if (overdueCount > 0 && lowStockCount > 0)
                    const SizedBox(height: AppSpacing.md),
                  if (lowStockCount > 0)
                    AlertCard(
                      message: s.lowStock(lowStockCount),
                      tone: AlertTone.warning,
                      actionLabel: s.viewInventory,
                      onAction: () => _push(const InventoryScreen()),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _TodaySummary(
            sales: sales,
            profit: profit,
            expense: expense,
            onTap: () => _push(const ExpensesScreen()),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String today =
        DateFormat('d MMMM, yyyy', s.localeCode).format(DateTime.now());
    final String initial =
        userName.trim().isEmpty ? '\u2014' : userName.trim().characters.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: textTheme.titleMedium?.copyWith(color: AppColors.darkGreen),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.greeting, style: textTheme.bodySmall),
                Text(
                  userName.trim().isEmpty ? '\u2014' : '$userName \u{1F44B}',
                  style: textTheme.titleMedium,
                ),
                Text(today, style: textTheme.labelSmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: s.notifications,
            icon: const Icon(Icons.notifications_none_rounded, size: 26),
          ),
        ],
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  const _ProBanner();

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        color: AppColors.darkGreen,
        shadows: AppShadows.raised,
        onTap: () {},
        child: Row(
          children: <Widget>[
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: AppRadius.field,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.proTitle,
                    style: textTheme.titleSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.proBody,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.sales,
    required this.profit,
    required this.debtGiven,
    required this.debtReturned,
  });

  final double sales;
  final double profit;
  final double debtGiven;
  final double debtReturned;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                  title: s.statSales,
                  amount: sales,
                  icon: Icons.shopping_cart_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  title: s.statProfit,
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
                  title: s.statDebtGiven,
                  amount: debtGiven,
                  icon: Icons.arrow_upward_rounded,
                  accentColor: AppColors.danger,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  title: s.statDebtReturned,
                  amount: debtReturned,
                  icon: Icons.arrow_downward_rounded,
                  accentColor: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpen});

  /// Ekranni push qiladi va qaytganda dashboardni yangilaydi.
  final Future<void> Function(Widget screen) onOpen;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        children: <Widget>[
          Expanded(
            child: QuickActionButton(
              label: s.quickSale,
              icon: Icons.shopping_basket_rounded,
              color: AppColors.primary,
              onTap: () => onOpen(const SaleFormScreen()),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: QuickActionButton(
              label: s.quickDebt,
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.danger,
              onTap: () => onOpen(const DebtFormScreen()),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: QuickActionButton(
              label: s.quickPayment,
              icon: Icons.payments_rounded,
              color: AppColors.info,
              onTap: () => onOpen(const DebtsScreen()),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: QuickActionButton(
              label: s.quickStockIn,
              icon: Icons.inventory_rounded,
              color: AppColors.warning,
              onTap: () => onOpen(const InventoryScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.sales,
    required this.profit,
    required this.expense,
    required this.onTap,
  });

  final double sales;
  final double profit;
  final double expense;

  /// Xarajatlar ekranini ochadi.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.today_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(s.todayTitle, style: textTheme.titleSmall),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              s.todaySummary(
                sales: Money.format(sales),
                profit: Money.format(profit),
                expense: Money.format(expense),
              ),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
