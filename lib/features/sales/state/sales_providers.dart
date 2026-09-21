import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_providers.dart';
import '../data/sale_models.dart';
import '../data/sales_repository.dart';

final Provider<SalesRepository> salesRepositoryProvider =
    Provider<SalesRepository>(
  (Ref ref) => SalesRepository(ref.watch(apiClientProvider)),
);

class SalesListState {
  const SalesListState({
    this.isLoading = true,
    this.items = const <Sale>[],
    this.summary,
    this.error,
    this.search = '',
    this.filterIndex = 0,
  });

  final bool isLoading;
  final List<Sale> items;
  final SalesSummary? summary;
  final ApiException? error;
  final String search;

  /// 0 — barchasi, keyingilari `SalesController.filters` bilan mos.
  final int filterIndex;

  bool get hasQuery => search.trim().isNotEmpty || filterIndex != 0;

  SalesListState copyWith({
    bool? isLoading,
    List<Sale>? items,
    SalesSummary? summary,
    ApiException? error,
    bool clearError = false,
    String? search,
    int? filterIndex,
  }) {
    return SalesListState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      filterIndex: filterIndex ?? this.filterIndex,
    );
  }
}

class SalesController extends StateNotifier<SalesListState> {
  SalesController(this._repository) : super(const SalesListState());

  /// `saleFilters` matnlari bilan bir tartibda: all + payment_method.
  static const List<String> filters = <String>[
    'all',
    'cash',
    'card',
    'debt',
    'mixed',
  ];

  final SalesRepository _repository;
  Timer? _debounce;
  int _requestId = 0;

  Future<void> load() async {
    final int requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<Sale> items = await _repository.list(
        search: state.search,
        paymentMethod:
            state.filterIndex == 0 ? null : filters[state.filterIndex],
      );
      final SalesSummary summary = await _repository.summary();
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

final StateNotifierProvider<SalesController, SalesListState>
    salesControllerProvider =
    StateNotifierProvider<SalesController, SalesListState>(
  (Ref ref) => SalesController(ref.watch(salesRepositoryProvider)),
);
