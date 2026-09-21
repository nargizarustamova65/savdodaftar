import '../../customers/data/customer_models.dart';

/// Qarz daftari modellari — TZ 7 va 28-bo'lim (`debts`, `debt_payments`).

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

class Debt {
  const Debt({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paidAmount,
    required this.remaining,
    required this.status,
    required this.issuedAt,
    this.customer,
    this.isOverdue = false,
    this.dueDate,
    this.note,
    this.payments = const <DebtPayment>[],
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    final Object? rawCustomer = json['customer'];
    final Object? rawPayments = json['payments'];

    return Debt(
      id: _asInt(json['id']),
      customerId: _asInt(json['customer_id']),
      customer: rawCustomer is Map
          ? Customer.fromJson(rawCustomer.cast<String, dynamic>())
          : null,
      amount: _asDouble(json['amount']),
      paidAmount: _asDouble(json['paid_amount']),
      remaining: _asDouble(json['remaining']),
      status: json['status']?.toString() ?? 'open',
      isOverdue: json['is_overdue'] == true,
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
      issuedAt:
          DateTime.tryParse(json['issued_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      note: _asStringOrNull(json['note']),
      payments: rawPayments is List
          ? rawPayments
              .whereType<Map<Object?, Object?>>()
              .map((Map<Object?, Object?> it) =>
                  DebtPayment.fromJson(it.cast<String, dynamic>()))
              .toList()
          : const <DebtPayment>[],
    );
  }

  final int id;
  final int customerId;
  final Customer? customer;
  final double amount;
  final double paidAmount;
  final double remaining;

  /// open | partial | paid (backend `debts.status`).
  final String status;
  final bool isOverdue;
  final DateTime? dueDate;
  final DateTime issuedAt;
  final String? note;
  final List<DebtPayment> payments;

  bool get isPaid => status == 'paid';
}

class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.paymentMethod,
    this.note,
  });

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: _asInt(json['id']),
      amount: _asDouble(json['amount']),
      paidAt:
          DateTime.tryParse(json['paid_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      paymentMethod: _asStringOrNull(json['payment_method']),
      note: _asStringOrNull(json['note']),
    );
  }

  final int id;
  final double amount;
  final DateTime paidAt;
  final String? paymentMethod;
  final String? note;
}

/// GET /debts/summary — dashboard va qarzlar sarlavhasi uchun.
class DebtsSummary {
  const DebtsSummary({
    required this.totalOutstanding,
    required this.debtorsCount,
    required this.overdueCount,
    required this.overdueAmount,
    required this.dueSoonCount,
    this.givenToday = 0,
    this.returnedToday = 0,
  });

  factory DebtsSummary.fromJson(Map<String, dynamic> json) {
    return DebtsSummary(
      totalOutstanding: _asDouble(json['total_outstanding']),
      debtorsCount: _asInt(json['debtors_count']),
      overdueCount: _asInt(json['overdue_count']),
      overdueAmount: _asDouble(json['overdue_amount']),
      dueSoonCount: _asInt(json['due_soon_count']),
      givenToday: _asDouble(json['given_today']),
      returnedToday: _asDouble(json['returned_today']),
    );
  }

  final double totalOutstanding;
  final int debtorsCount;
  final int overdueCount;
  final double overdueAmount;
  final int dueSoonCount;

  /// Bugun berilgan qarz — dashboard "Berilgan qarz" kartasi.
  /// Backend `given_today` yubormasa 0 bo'ladi.
  final double givenToday;

  /// Bugun qaytgan qarz — dashboard "Qaytgan qarz" kartasi.
  final double returnedToday;
}
