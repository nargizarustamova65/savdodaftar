import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/widgets.dart';
import 'data/expense_models.dart';
import 'expense_form_screen.dart';
import 'state/expenses_providers.dart';

/// TZ 14-bo'lim: xarajatlar — summary, davr/kategoriya filtri va ro'yxat.
///
/// Yozuvni o'chirish: kartani bosib turish (long press) -> tasdiqlash.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(expensesControllerProvider.notifier).load(),
    );
  }

  Future<void> _openForm() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const ExpenseFormScreen(),
      ),
    );
    if (created == true && mounted) {
      await ref.read(expensesControllerProvider.notifier).load();
    }
  }

  Future<void> _confirmDelete(Expense expense) async {
    final AppStrings s = context.s;
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: s.deleteExpenseTitle,
      message: s.deleteExpenseBody,
      confirmLabel: s.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await ref.read(expensesRepositoryProvider).delete(expense.id);
      if (mounted) {
        await ref.read(expensesControllerProvider.notifier).load();
      }
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
    final ExpensesListState state = ref.watch(expensesControllerProvider);
    final ExpensesController notifier =
        ref.read(expensesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.navExpenses)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.expenseAddTitle),
      ),
      body: Column(
        children: <Widget>[
          if (state.summary != null) ...<Widget>[
            _SummaryCard(summary: state.summary!),
            const SizedBox(height: AppSpacing.md),
          ],
          AppFilterChips(
            labels: s.expensePeriods,
            selectedIndex: state.periodIndex,
            onSelected: notifier.setPeriod,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFilterChips(
            labels: <String>[s.filterAll, ...s.expenseCategories],
            selectedIndex: state.categoryIndex,
            onSelected: notifier.setCategory,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildBody(s, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppStrings s,
    ExpensesListState state,
    ExpensesController notifier,
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
        icon: Icons.receipt_long_outlined,
        title: s.expensesEmptyTitle,
        message: s.expensesEmptyBody,
        actionLabel: s.expenseAddTitle,
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
          final Expense expense = state.items[index];
          return _ExpenseTile(
            expense: expense,
            onLongPress: () => _confirmDelete(expense),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ExpensesSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: AppRadius.field,
              ),
              child: const Icon(
                Icons.trending_down_rounded,
                size: 20,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(s.totalExpenseLabel, style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  MoneyText(
                    summary.total,
                    size: 18,
                    color: summary.total > 0
                        ? AppColors.danger
                        : AppColors.textPrimary,
                  ),
                ],
              ),
            ),
            Text(
              s.expensesCountText(summary.count),
              style: textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.onLongPress});

  final Expense expense;
  final VoidCallback onLongPress;

  static IconData _categoryIcon(String category) {
    return switch (category) {
      'rent' => Icons.home_work_rounded,
      'transport' => Icons.local_shipping_rounded,
      'salary' => Icons.badge_rounded,
      'ads' => Icons.campaign_rounded,
      'electricity' => Icons.bolt_rounded,
      'internet' => Icons.wifi_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        child: Row(
          children: <Widget>[
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: AppRadius.field,
              ),
              child: Icon(
                _categoryIcon(expense.category),
                size: 20,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.expenseCategoryText(expense.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  if (expense.note != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      expense.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(expense.spentAt),
                    style: textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            MoneyText(
              expense.amount,
              size: 15,
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}
