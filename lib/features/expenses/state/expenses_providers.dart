import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_providers.dart';
import '../data/expense_models.dart';
import '../data/expenses_repository.dart';

final Provider<ExpensesRepository> expensesRepositoryProvider =
    Provider<ExpensesRepository>(
  (Ref ref) => ExpensesRepository(ref.watch(apiClientProvider)),
);

class ExpensesListState {
  const ExpensesListState({
    this.isLoading = true,
    this.items = const <Expense>[],
    this.summary,
    this.error,
    this.periodIndex = 0,
    this.categoryIndex = 0,
  });

  final bool isLoading;
  final List<Expense> items;
  final ExpensesSummary? summary;
  final ApiException? error;

  /// 0 — bugun, 1 — 7 kun, 2 — 30 kun, 3 — barchasi
  /// (`AppStrings.expensePeriods` bilan bir tartibda).
  final int periodIndex;

  /// 0 — barcha kategoriyalar, 1.. — `AppStrings.expenseCategoryKeys`.
  final int categoryIndex;

  bool get hasQuery => categoryIndex != 0;

  ExpensesListState copyWith({
    bool? isLoading,
    List<Expense>? items,
    ExpensesSummary? summary,
    ApiException? error,
    bool clearError = false,
    int? periodIndex,
    int? categoryIndex,
  }) {
    return ExpensesListState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      error: clearError ? null : (error ?? this.error),
      periodIndex: periodIndex ?? this.periodIndex,
      categoryIndex: categoryIndex ?? this.categoryIndex,
    );
  }
}

class ExpensesController extends StateNotifier<ExpensesListState> {
  ExpensesController(this._repository) : super(const ExpensesListState());

  /// Backend `period` bilan bir tartibda (`expensePeriods` matnlariga mos).
  static const List<String> periods = <String>['day', 'week', 'month', 'all'];

  /// Backend `expenses.category` kalitlari (filtr uchun, 0 — barchasi).
  static const List<String> categories = <String>[
    'rent',
    'transport',
    'salary',
    'ads',
    'electricity',
    'internet',
    'other',
  ];

  final ExpensesRepository _repository;
  int _requestId = 0;

  Future<void> load() async {
    final int requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final String period = periods[state.periodIndex];
      final List<Expense> items = await _repository.list(
        period: period,
        category: state.categoryIndex == 0
            ? null
            : categories[state.categoryIndex - 1],
      );
      final ExpensesSummary summary =
          await _repository.summary(period: period);
      if (requestId != _requestId || !mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        items: items,
        summary: summary,
      );
    } on ApiException catch (error) {
      if (requestId != _requestId || !mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  void setPeriod(int index) {
    if (index == state.periodIndex) {
      return;
    }
    state = state.copyWith(periodIndex: index);
    load();
  }

  void setCategory(int index) {
    if (index == state.categoryIndex) {
      return;
    }
    state = state.copyWith(categoryIndex: index);
    load();
  }
}

final StateNotifierProvider<ExpensesController, ExpensesListState>
    expensesControllerProvider =
    StateNotifierProvider<ExpensesController, ExpensesListState>(
  (Ref ref) => ExpensesController(ref.watch(expensesRepositoryProvider)),
);
