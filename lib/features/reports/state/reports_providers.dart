import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../expenses/data/expense_models.dart';
import '../../expenses/state/expenses_providers.dart';
import '../../sales/data/sale_models.dart';
import '../../sales/state/sales_providers.dart';

/// TZ 17-bo'lim: hisobot holati — GET /sales/summary?from=&to= va
/// GET /expenses/summary?from=&to= asosida.
class ReportsState {
  const ReportsState({
    this.isLoading = true,
    this.periodIndex = 0,
    this.customFrom,
    this.customTo,
    this.sales,
    this.expenses,
    this.error,
  });

  final bool isLoading;

  /// 0 — bugun, 1 — 7 kun, 2 — 30 kun, 3 — custom davr
  /// (`AppStrings.reportPeriods` bilan bir tartibda).
  final int periodIndex;
  final DateTime? customFrom;
  final DateTime? customTo;
  final SalesSummary? sales;

  /// Backend `/expenses` hali tayyor bo'lmasa null qoladi.
  final ExpensesSummary? expenses;
  final ApiException? error;

  bool get hasData => sales != null;

  /// Sof foyda = yalpi foyda − xarajatlar (TZ 14).
  double get netProfit => (sales?.profit ?? 0) - (expenses?.total ?? 0);

  ReportsState copyWith({
    bool? isLoading,
    int? periodIndex,
    DateTime? customFrom,
    DateTime? customTo,
    SalesSummary? sales,
    ExpensesSummary? expenses,
    ApiException? error,
    bool clearError = false,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      periodIndex: periodIndex ?? this.periodIndex,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
      sales: sales ?? this.sales,
      expenses: expenses ?? this.expenses,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReportsController extends StateNotifier<ReportsState> {
  ReportsController(this._ref) : super(const ReportsState());

  final Ref _ref;
  int _requestId = 0;

  static String _ymd(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  /// Tanlangan davr chegaralari: (from, to).
  (DateTime, DateTime) range() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return switch (state.periodIndex) {
      1 => (today.subtract(const Duration(days: 6)), today),
      2 => (today.subtract(const Duration(days: 29)), today),
      3 => (state.customFrom ?? today, state.customTo ?? today),
      _ => (today, today),
    };
  }

  Future<void> load() async {
    final int requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    final (DateTime fromDate, DateTime toDate) = range();
    final String from = _ymd(fromDate);
    final String to = _ymd(toDate);

    try {
      final SalesSummary sales =
          await _ref.read(salesRepositoryProvider).summary(from: from, to: to);

      // Xarajatlar endpointi backendda hali bo'lmasligi mumkin —
      // uning xatosi hisobotni to'xtatmaydi.
      ExpensesSummary? expenses;
      try {
        expenses = await _ref
            .read(expensesRepositoryProvider)
            .summary(from: from, to: to);
      } on ApiException {
        expenses = null;
      }

      if (requestId != _requestId || !mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        sales: sales,
        expenses: expenses,
      );
    } on ApiException catch (error) {
      if (requestId != _requestId || !mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// Custom davr (3) tanlanganda sana oralig'i so'ralguncha yuklamaydi.
  void setPeriod(int index) {
    if (index == state.periodIndex) {
      return;
    }
    state = state.copyWith(periodIndex: index);
    if (index != 3 || (state.customFrom != null && state.customTo != null)) {
      load();
    }
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(periodIndex: 3, customFrom: from, customTo: to);
    load();
  }
}

final StateNotifierProvider<ReportsController, ReportsState>
    reportsControllerProvider =
    StateNotifierProvider<ReportsController, ReportsState>(
  ReportsController.new,
);
