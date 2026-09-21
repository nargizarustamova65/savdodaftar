import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'debt_models.dart';

/// `/api/v1/debts` endpointlari bilan ishlaydi (savdodaftar-backend).
class DebtsRepository {
  const DebtsRepository(this._client);

  final ApiClient _client;

  /// GET /debts?status=all|unpaid|overdue|paid&customer_id=&search=&sort=
  Future<List<Debt>> list({
    String status = 'all',
    int? customerId,
    String? search,
    String sort = 'recent',
    int perPage = 100,
  }) async {
    final ApiResponse response = await _client.get(
      '/debts',
      query: <String, dynamic>{
        'status': status,
        if (customerId != null) 'customer_id': customerId,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        'sort': sort,
        'per_page': perPage,
      },
    );

    return response.dataList.map(Debt.fromJson).toList();
  }

  Future<DebtsSummary> summary() async {
    final ApiResponse response = await _client.get('/debts/summary');
    return DebtsSummary.fromJson(response.dataMap);
  }

  /// POST /debts — `due_date` formati: `YYYY-MM-DD`.
  Future<Debt> create({
    required int customerId,
    required int amount,
    String? note,
    String? dueDate,
  }) async {
    final ApiResponse response = await _client.post(
      '/debts',
      body: <String, dynamic>{
        'customer_id': customerId,
        'amount': amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (dueDate != null) 'due_date': dueDate,
      },
    );

    return Debt.fromJson(response.dataMap);
  }

  /// GET /debts/{id} — to'lovlar ro'yxati bilan.
  Future<Debt> fetch(int id) async {
    final ApiResponse response = await _client.get('/debts/$id');
    return Debt.fromJson(response.dataMap);
  }

  /// POST /debts/{id}/payments — qisman to'lovni qabul qilish.
  Future<({Debt debt, String message})> pay(
    int id, {
    required int amount,
    String method = 'cash',
    String? note,
  }) async {
    final ApiResponse response = await _client.post(
      '/debts/$id/payments',
      body: <String, dynamic>{
        'amount': amount,
        'payment_method': method,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    final Object? rawDebt = response.dataMap['debt'];
    return (
      debt: Debt.fromJson(
        rawDebt is Map ? rawDebt.cast<String, dynamic>() : <String, dynamic>{},
      ),
      message: response.message,
    );
  }

  Future<void> delete(int id) => _client.delete('/debts/$id');
}
