import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'expense_models.dart';

/// `/api/v1/expenses` endpointlari bilan ishlaydi (sotuvdaftar-backend).
class ExpensesRepository {
  const ExpensesRepository(this._client);

  final ApiClient _client;

  /// GET /expenses?period=day|week|month|all&category=&per_page=
  Future<List<Expense>> list({
    String period = 'day',
    String? category,
    int perPage = 100,
  }) async {
    final ApiResponse response = await _client.get(
      '/expenses',
      query: <String, dynamic>{
        'period': period,
        if (category != null) 'category': category,
        'per_page': perPage,
      },
    );

    return response.dataList.map(Expense.fromJson).toList();
  }

  /// GET /expenses/summary?period= yoki ?from=&to= (custom davr, TZ 17).
  Future<ExpensesSummary> summary({
    String period = 'day',
    String? from,
    String? to,
  }) async {
    final ApiResponse response = await _client.get(
      '/expenses/summary',
      query: <String, dynamic>{
        if (from == null && to == null) 'period': period,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return ExpensesSummary.fromJson(response.dataMap);
  }

  /// POST /expenses — `spent_at` formati: `YYYY-MM-DD`.
  Future<Expense> create({
    required String category,
    required int amount,
    String? note,
    String? spentAt,
  }) async {
    final ApiResponse response = await _client.post(
      '/expenses',
      body: <String, dynamic>{
        'category': category,
        'amount': amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (spentAt != null) 'spent_at': spentAt,
      },
    );

    return Expense.fromJson(response.dataMap);
  }

  Future<void> delete(int id) => _client.delete('/expenses/$id');
}
