import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/phone.dart';
import 'customer_models.dart';

/// `/api/v1/customers` endpointlari bilan ishlaydi (savdodaftar-backend).
class CustomersRepository {
  const CustomersRepository(this._client);

  final ApiClient _client;

  /// GET /customers?search=&filter=all|debtors|clean&sort=name|balance|recent
  Future<List<Customer>> list({
    String? search,
    String filter = 'all',
    String sort = 'name',
    int perPage = 200,
  }) async {
    final ApiResponse response = await _client.get(
      '/customers',
      query: <String, dynamic>{
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        'filter': filter,
        'sort': sort,
        'per_page': perPage,
      },
    );

    return response.dataList.map(Customer.fromJson).toList();
  }

  Future<Customer> fetch(int id) async {
    final ApiResponse response = await _client.get('/customers/$id');
    return Customer.fromJson(response.dataMap);
  }

  Future<Customer> create({
    required String name,
    String? phone,
    String? address,
    String? note,
  }) async {
    final ApiResponse response = await _client.post(
      '/customers',
      body: _body(name: name, phone: phone, address: address, note: note),
    );
    return Customer.fromJson(response.dataMap);
  }

  Future<Customer> update(
    int id, {
    required String name,
    String? phone,
    String? address,
    String? note,
  }) async {
    final ApiResponse response = await _client.put(
      '/customers/$id',
      body: _body(name: name, phone: phone, address: address, note: note),
    );
    return Customer.fromJson(response.dataMap);
  }

  Future<void> delete(int id) => _client.delete('/customers/$id');

  /// Qarzlar, to'lovlar va savdolar birlashtirilgan tarixi.
  Future<CustomerHistory> history(int id, {int limit = 100}) async {
    final ApiResponse response = await _client.get(
      '/customers/$id/history',
      query: <String, dynamic>{'limit': limit},
    );
    return CustomerHistory.fromJson(response.dataMap);
  }

  /// Mijoz bo'yicha to'lov — backend qarzlarga FIFO taqsimlaydi.
  /// Muvaffaqiyatda yangilangan mijoz va backend xabari qaytadi.
  Future<({Customer customer, String message})> pay(
    int id, {
    required int amount,
    String method = 'cash',
    String? note,
  }) async {
    final ApiResponse response = await _client.post(
      '/customers/$id/payments',
      body: <String, dynamic>{
        'amount': amount,
        'payment_method': method,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    final Object? rawCustomer = response.dataMap['customer'];
    return (
      customer: Customer.fromJson(
        rawCustomer is Map
            ? rawCustomer.cast<String, dynamic>()
            : <String, dynamic>{},
      ),
      message: response.message,
    );
  }

  Map<String, dynamic> _body({
    required String name,
    String? phone,
    String? address,
    String? note,
  }) {
    final String trimmedPhone = phone?.trim() ?? '';
    final String trimmedAddress = address?.trim() ?? '';
    final String trimmedNote = note?.trim() ?? '';

    return <String, dynamic>{
      'name': name.trim(),
      'phone': trimmedPhone.isEmpty ? null : Phone.toE164(trimmedPhone),
      'address': trimmedAddress.isEmpty ? null : trimmedAddress,
      'note': trimmedNote.isEmpty ? null : trimmedNote,
    };
  }
}
