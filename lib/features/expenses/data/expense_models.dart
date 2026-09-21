/// Xarajatlar modellari — TZ 14 va 28-bo'lim (`expenses`).

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _asStringOrNull(Object? value) {
  final String? text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.spentAt,
    this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: _asInt(json['id']),
      category: json['category']?.toString() ?? 'other',
      amount: _asDouble(json['amount']),
      spentAt:
          DateTime.tryParse(json['spent_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      note: _asStringOrNull(json['note']),
    );
  }

  final int id;

  /// rent | transport | salary | ads | electricity | internet | other
  /// (backend `expenses.category`).
  final String category;
  final double amount;
  final DateTime spentAt;
  final String? note;
}

/// GET /expenses/summary — davr bo'yicha jami xarajat.
class ExpensesSummary {
  const ExpensesSummary({
    required this.total,
    required this.count,
    this.byCategory = const <String, double>{},
  });

  factory ExpensesSummary.fromJson(Map<String, dynamic> json) {
    final Object? raw = json['by_category'];
    final Map<String, double> byCategory = <String, double>{};
    if (raw is List) {
      for (final Object? it in raw) {
        if (it is Map) {
          final Map<String, dynamic> map = it.cast<String, dynamic>();
          byCategory[map['category']?.toString() ?? 'other'] =
              _asDouble(map['total']);
        }
      }
    }

    return ExpensesSummary(
      total: _asDouble(json['total']),
      count: _asInt(json['count']),
      byCategory: byCategory,
    );
  }

  final double total;
  final int count;
  final Map<String, double> byCategory;
}
