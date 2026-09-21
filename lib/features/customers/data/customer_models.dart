/// Mijozlar moduli modellari — TZ 9–10 va 28-bo'lim (`customers` jadvali).
library;

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

int? _asIntOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

String? _asStringOrNull(Object? value) {
  final String? text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    this.balance = 0,
    this.isDebtor = false,
    this.openDebtsCount,
    this.overdueDebtsCount,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      phone: _asStringOrNull(json['phone']),
      address: _asStringOrNull(json['address']),
      note: _asStringOrNull(json['note']),
      balance: _asDouble(json['balance']),
      isDebtor: json['is_debtor'] == true,
      openDebtsCount: _asIntOrNull(json['open_debts_count']),
      overdueDebtsCount: _asIntOrNull(json['overdue_debts_count']),
    );
  }

  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;

  /// Musbat balans — mijozning qarzi (TZ: qoldiq qarz avtomatik hisoblanadi).
  final double balance;
  final bool isDebtor;
  final int? openDebtsCount;
  final int? overdueDebtsCount;
}

/// Tarix elementining turi — backend `history.items[].type`.
enum HistoryType {
  debt,
  payment,
  sale,
  other;

  static HistoryType parse(String? value) {
    return switch (value) {
      'debt' => HistoryType.debt,
      'payment' => HistoryType.payment,
      'sale' => HistoryType.sale,
      _ => HistoryType.other,
    };
  }
}

class CustomerHistoryItem {
  const CustomerHistoryItem({
    required this.type,
    required this.id,
    required this.amount,
    required this.date,
    this.remaining,
    this.status,
    this.isOverdue = false,
    this.dueDate,
    this.paymentMethod,
    this.note,
    this.itemsCount,
  });

  factory CustomerHistoryItem.fromJson(Map<String, dynamic> json) {
    return CustomerHistoryItem(
      type: HistoryType.parse(json['type']?.toString()),
      id: _asInt(json['id']),
      amount: _asDouble(json['amount']),
      date: DateTime.tryParse(json['date']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      remaining: json['remaining'] == null ? null : _asDouble(json['remaining']),
      status: _asStringOrNull(json['status']),
      isOverdue: json['is_overdue'] == true,
      dueDate: _asStringOrNull(json['due_date']),
      paymentMethod: _asStringOrNull(json['payment_method']),
      note: _asStringOrNull(json['note']),
      itemsCount: _asIntOrNull(json['items_count']),
    );
  }

  final HistoryType type;
  final int id;
  final double amount;
  final DateTime date;
  final double? remaining;
  final String? status;
  final bool isOverdue;
  final String? dueDate;
  final String? paymentMethod;
  final String? note;
  final int? itemsCount;
}

class CustomerHistory {
  const CustomerHistory({required this.customer, required this.items});

  factory CustomerHistory.fromJson(Map<String, dynamic> json) {
    final Object? rawCustomer = json['customer'];
    final Object? rawItems = json['items'];

    return CustomerHistory(
      customer: Customer.fromJson(
        rawCustomer is Map
            ? rawCustomer.cast<String, dynamic>()
            : <String, dynamic>{},
      ),
      items: rawItems is List
          ? rawItems
              .whereType<Map<Object?, Object?>>()
              .map((Map<Object?, Object?> it) =>
                  CustomerHistoryItem.fromJson(it.cast<String, dynamic>()))
              .toList()
          : <CustomerHistoryItem>[],
    );
  }

  final Customer customer;
  final List<CustomerHistoryItem> items;
}
