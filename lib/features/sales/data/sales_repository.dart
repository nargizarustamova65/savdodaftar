import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'sale_models.dart';

/// `/api/v1/sales` endpointlari bilan ishlaydi (savdodaftar-backend).
class SalesRepository {
  const SalesRepository(this._client);

  final ApiClient _client;

  /// GET /sales?from=&to=&customer_id=&payment_method=&search=
  Future<List<Sale>> list({
    String? from,
    String? to,
    int? customerId,
    String? paymentMethod,
    String? search,
    int perPage = 100,
  }) async {
    final ApiResponse response = await _client.get(
      '/sales',
      query: <String, dynamic>{
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (customerId != null) 'customer_id': customerId,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'payment_method': paymentMethod,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        'per_page': perPage,
      },
    );

    return response.dataList.map(Sale.fromJson).toList();
  }

  /// GET /sales/summary — default bugun.
  Future<SalesSummary> summary({String? from, String? to}) async {
    final ApiResponse response = await _client.get(
      '/sales/summary',
      query: <String, dynamic>{
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return SalesSummary.fromJson(response.dataMap);
  }

  /// POST /sales — TZ 27 "Savdo" oqimi.
  ///
  /// [items] elementlari: ombordagi mahsulot uchun `product_id`,
  /// tezkor mahsulot uchun `name` + `price`; ikkalasida ham `qty`.
  Future<({Sale sale, String message})> create({
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    int? customerId,
    num? paidCash,
    num? paidCard,
    num? debtAmount,
    String? dueDate,
    num? discount,
    String? note,
  }) async {
    final ApiResponse response = await _client.post(
      '/sales',
      body: <String, dynamic>{
        'payment_method': paymentMethod,
        'items': items,
        if (customerId != null) 'customer_id': customerId,
        if (paidCash != null) 'paid_cash': paidCash,
        if (paidCard != null) 'paid_card': paidCard,
        if (debtAmount != null) 'debt_amount': debtAmount,
        if (dueDate != null) 'due_date': dueDate,
        if (discount != null && discount > 0) 'discount': discount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    return (
      sale: Sale.fromJson(response.dataMap),
      message: response.message,
    );
  }

  /// GET /sales/{id} — mahsulotlar va qaytarishlar bilan.
  Future<Sale> fetch(int id) async {
    final ApiResponse response = await _client.get('/sales/$id');
    return Sale.fromJson(response.dataMap);
  }

  /// GET /sales/{id}/receipt — elektron chek (TZ 16).
  Future<SaleReceipt> receipt(int id) async {
    final ApiResponse response = await _client.get('/sales/$id/receipt');
    return SaleReceipt.fromJson(response.dataMap);
  }
}
