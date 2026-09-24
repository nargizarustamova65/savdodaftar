import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_providers.dart';
import '../data/product_models.dart';
import '../data/products_repository.dart';

final Provider<ProductsRepository> productsRepositoryProvider =
    Provider<ProductsRepository>(
  (Ref ref) => ProductsRepository(ref.watch(apiClientProvider)),
);

class ProductsListState {
  const ProductsListState({
    this.isLoading = true,
    this.items = const <Product>[],
    this.summary,
    this.error,
    this.search = '',
    this.filterIndex = 0,
    this.categories = const <String>[],
    this.categoryIndex = 0,
  });

  final bool isLoading;
  final List<Product> items;
  final ProductsSummary? summary;
  final ApiException? error;
  final String search;

  /// 0 — barchasi, 1 — kam qoldiq, 2 — tugagan.
  final int filterIndex;

  /// Backend'dagi mavjud kategoriyalar (GET /products/categories).
  final List<String> categories;

  /// 0 — barcha kategoriyalar, aks holda `categories[categoryIndex - 1]`.
  final int categoryIndex;

  bool get hasQuery =>
      search.trim().isNotEmpty || filterIndex != 0 || categoryIndex != 0;

  /// Tanlangan kategoriya nomi yoki null (barchasi).
  String? get selectedCategory =>
      categoryIndex >= 1 && categoryIndex <= categories.length
          ? categories[categoryIndex - 1]
          : null;

  ProductsListState copyWith({
    bool? isLoading,
    List<Product>? items,
    ProductsSummary? summary,
    ApiException? error,
    bool clearError = false,
    String? search,
    int? filterIndex,
    List<String>? categories,
    int? categoryIndex,
  }) {
    return ProductsListState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      filterIndex: filterIndex ?? this.filterIndex,
      categories: categories ?? this.categories,
      categoryIndex: categoryIndex ?? this.categoryIndex,
    );
  }
}

class ProductsController extends StateNotifier<ProductsListState> {
  ProductsController(this._repository) : super(const ProductsListState());

  /// Backend `filter` bilan bir tartibda (`productFilters` matnlariga mos).
  static const List<String> filters = <String>[
    'all',
    'low_stock',
    'out_of_stock',
  ];

  final ProductsRepository _repository;
  Timer? _debounce;
  int _requestId = 0;

  Future<void> load() async {
    final int requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<Product> items = await _repository.list(
        search: state.search,
        category: state.selectedCategory,
        filter: filters[state.filterIndex],
        sort: state.filterIndex == 0 ? 'name' : 'stock',
      );
      final ProductsSummary summary = await _repository.summary();
      final List<String> categories = await _repository.categories();
      if (requestId != _requestId || !mounted) {
        return;
      }
      // Tanlangan kategoriya ro'yxatdan chiqib ketgan bo'lsa filtr tozalanadi.
      final String? selected = state.selectedCategory;
      final int categoryIndex =
          selected == null ? 0 : categories.indexOf(selected) + 1;
      state = state.copyWith(
        isLoading: false,
        items: items,
        summary: summary,
        categories: categories,
        categoryIndex: categoryIndex,
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

  void setCategory(int index) {
    if (index == state.categoryIndex) {
      return;
    }
    state = state.copyWith(categoryIndex: index);
    load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<ProductsController, ProductsListState>
    productsControllerProvider =
    StateNotifierProvider<ProductsController, ProductsListState>(
  (Ref ref) => ProductsController(ref.watch(productsRepositoryProvider)),
);
