import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_providers.dart';
import '../data/debt_models.dart';
import '../data/debts_repository.dart';

final Provider<DebtsRepository> debtsRepositoryProvider =
    Provider<DebtsRepository>(
  (Ref ref) => DebtsRepository(ref.watch(apiClientProvider)),
);

class DebtsListState {
  const DebtsListState({
    this.isLoading = true,
    this.items = const <Debt>[],
    this.summary,
    this.error,
    this.search = '',
    this.filterIndex = 0,
  });

  final bool isLoading;
  final List<Debt> items;
  final DebtsSummary? summary;
  final ApiException? error;
  final String search;

  /// 0 — barchasi, 1 — ochiq, 2 — muddati o'tgan, 3 — to'langan.
  final int filterIndex;

  bool get hasQuery => search.trim().isNotEmpty || filterIndex != 0;

  DebtsListState copyWith({
    bool? isLoading,
    List<Debt>? items,
    DebtsSummary? summary,
    ApiException? error,
    bool clearError = false,
    String? search,
    int? filterIndex,
  }) {
    return DebtsListState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      filterIndex: filterIndex ?? this.filterIndex,
    );
  }
}

class DebtsController extends StateNotifier<DebtsListState> {
  DebtsController(this._repository) : super(const DebtsListState());

  /// Backend `status` bilan bir tartibda (`debtFilters` matnlariga mos).
  static const List<String> filters = <String>[
    'all',
    'unpaid',
    'overdue',
    'paid',
  ];

  final DebtsRepository _repository;
  Timer? _debounce;
  int _requestId = 0;

  Future<void> load() async {
    final int requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<Debt> items = await _repository.list(
        status: filters[state.filterIndex],
        search: state.search,
        sort: state.filterIndex == 2 ? 'due_date' : 'recent',
      );
      final DebtsSummary summary = await _repository.summary();
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

  void setSearch(String value) {
    state = state.copyWith(search: value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  void setFilter(int index) {
    if (index == state.filterIndex) {
      return;
    }
    state = state.copyWith(filterIndex: index);
    load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<DebtsController, DebtsListState>
    debtsControllerProvider =
    StateNotifierProvider<DebtsController, DebtsListState>(
  (Ref ref) => DebtsController(ref.watch(debtsRepositoryProvider)),
);
