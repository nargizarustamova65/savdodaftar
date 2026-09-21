import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_providers.dart';
import '../data/customer_models.dart';
import '../data/customers_repository.dart';

final Provider<CustomersRepository> customersRepositoryProvider =
    Provider<CustomersRepository>(
  (Ref ref) => CustomersRepository(ref.watch(apiClientProvider)),
);

class CustomersListState {
  const CustomersListState({
    this.isLoading = true,
    this.items = const <Customer>[],
    this.error,
    this.search = '',
    this.filterIndex = 0,
  });

  final bool isLoading;
  final List<Customer> items;
  final ApiException? error;
  final String search;

  /// 0 — barchasi, 1 — qarzdorlar, 2 — qarzsiz (backend `filter` tartibi).
  final int filterIndex;

  bool get hasQuery => search.trim().isNotEmpty || filterIndex != 0;

  CustomersListState copyWith({
    bool? isLoading,
    List<Customer>? items,
    ApiException? error,
    bool clearError = false,
    String? search,
    int? filterIndex,
  }) {
    return CustomersListState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      filterIndex: filterIndex ?? this.filterIndex,
    );
  }
}

class CustomersController extends StateNotifier<CustomersListState> {
  CustomersController(this._repository) : super(const CustomersListState());

  static const List<String> filters = <String>['all', 'debtors', 'clean'];

  final CustomersRepository _repository;
  Timer? _debounce;
  int _requestId = 0;

  Future<void> load() async {
    final int requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<Customer> items = await _repository.list(
        search: state.search,
        filter: filters[state.filterIndex],
        sort: state.filterIndex == 1 ? 'balance' : 'name',
      );
      if (requestId != _requestId || !mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, items: items);
    } on ApiException catch (error) {
      if (requestId != _requestId || !mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// Qidiruv — 350 ms debounce bilan serverga so'rov yuboradi.
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

final StateNotifierProvider<CustomersController, CustomersListState>
    customersControllerProvider =
    StateNotifierProvider<CustomersController, CustomersListState>(
  (Ref ref) => CustomersController(ref.watch(customersRepositoryProvider)),
);
