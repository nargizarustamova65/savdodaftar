import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'product_models.dart';

/// `/api/v1/products` endpointlari bilan ishlaydi (savdodaftar-backend).
class ProductsRepository {
  const ProductsRepository(this._client);

  final ApiClient _client;

  /// GET /products?search=&category=&filter=&sort=
  Future<List<Product>> list({
    String? search,
    String? category,
    String filter = 'all',
    String sort = 'name',
    int perPage = 200,
  }) async {
    final ApiResponse response = await _client.get(
      '/products',
      query: <String, dynamic>{
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
        'filter': filter,
        'sort': sort,
        'per_page': perPage,
      },
    );

    return response.dataList.map(Product.fromJson).toList();
  }

  Future<ProductsSummary> summary() async {
    final ApiResponse response = await _client.get('/products/summary');
    return ProductsSummary.fromJson(response.dataMap);
  }

  /// GET /products/barcode/{barcode} — skaner uchun (V2).
  Future<Product> byBarcode(String barcode) async {
    final ApiResponse response =
        await _client.get('/products/barcode/${Uri.encodeComponent(barcode)}');
    return Product.fromJson(response.dataMap);
  }

  Future<Product> create({
    required String name,
    required int sellPrice,
    String? category,
    String? barcode,
    String unit = 'dona',
    int? buyPrice,
    double? stock,
    double? minStock,
  }) async {
    final ApiResponse response = await _client.post(
      '/products',
      body: _body(
        name: name,
        sellPrice: sellPrice,
        category: category,
        barcode: barcode,
        unit: unit,
        buyPrice: buyPrice,
        minStock: minStock,
      )..addAll(<String, dynamic>{if (stock != null) 'stock': stock}),
    );

    return Product.fromJson(response.dataMap);
  }

  /// PUT /products/{id} — qoldiq bu yerda o'zgarmaydi (kirim/chiqim orqali).
  Future<Product> update(
    int id, {
    required String name,
    required int sellPrice,
    String? category,
    String? barcode,
    String unit = 'dona',
    int? buyPrice,
    double? minStock,
  }) async {
    final ApiResponse response = await _client.put(
      '/products/$id',
      body: _body(
        name: name,
        sellPrice: sellPrice,
        category: category,
        barcode: barcode,
        unit: unit,
        buyPrice: buyPrice,
        minStock: minStock,
      ),
    );

    return Product.fromJson(response.dataMap);
  }

  /// GET /products/{id} — oxirgi 20 ta harakat bilan.
  Future<Product> fetch(int id) async {
    final ApiResponse response = await _client.get('/products/$id');
    return Product.fromJson(response.dataMap);
  }

  Future<void> delete(int id) => _client.delete('/products/$id');

  /// POST /products/{id}/stock-in — kirim (TZ 27 "Kirim" oqimi).
  Future<({Product product, String message})> stockIn(
    int id, {
    required double qty,
    int? buyPrice,
    bool updateBuyPrice = false,
    String? note,
  }) {
    return _movement(
      '/products/$id/stock-in',
      qty: qty,
      buyPrice: buyPrice,
      updateBuyPrice: updateBuyPrice,
      note: note,
    );
  }

  /// POST /products/{id}/stock-out — chiqim (yo'qotish, shaxsiy foydalanish).
  Future<({Product product, String message})> stockOut(
    int id, {
    required double qty,
    String? note,
  }) {
    return _movement('/products/$id/stock-out', qty: qty, note: note);
  }

  Future<({Product product, String message})> _movement(
    String path, {
    required double qty,
    int? buyPrice,
    bool updateBuyPrice = false,
    String? note,
  }) async {
    final ApiResponse response = await _client.post(
      path,
      body: <String, dynamic>{
        'qty': qty,
        if (buyPrice != null) 'buy_price': buyPrice,
        if (updateBuyPrice) 'update_buy_price': true,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    final Object? rawProduct = response.dataMap['product'];
    return (
      product: Product.fromJson(
        rawProduct is Map
            ? rawProduct.cast<String, dynamic>()
            : <String, dynamic>{},
      ),
      message: response.message,
    );
  }

  Map<String, dynamic> _body({
    required String name,
    required int sellPrice,
    String? category,
    String? barcode,
    String unit = 'dona',
    int? buyPrice,
    double? minStock,
  }) {
    final String trimmedCategory = category?.trim() ?? '';
    final String trimmedBarcode = barcode?.trim() ?? '';

    return <String, dynamic>{
      'name': name.trim(),
      'sell_price': sellPrice,
      'category': trimmedCategory.isEmpty ? null : trimmedCategory,
      'barcode': trimmedBarcode.isEmpty ? null : trimmedBarcode,
      'unit': unit,
      'buy_price': buyPrice,
      if (minStock != null) 'min_stock': minStock,
    };
  }
}
