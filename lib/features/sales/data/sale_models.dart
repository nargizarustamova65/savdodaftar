/// Savdo moduli modellari — TZ 6, 16, 27 va 28-bo'lim (`sales`, `sale_items`).
library;

import '../../customers/data/customer_models.dart';

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

class SaleItem {
  const SaleItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.qty,
    required this.price,
    required this.total,
    this.productId,
    this.returnedQty = 0,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: _asInt(json['id']),
      productId: _asIntOrNull(json['product_id']),
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'dona',
      qty: _asDouble(json['qty']),
      price: _asDouble(json['price']),
      total: _asDouble(json['total']),
      returnedQty: _asDouble(json['returned_qty']),
    );
  }

  final int id;
  final int? productId;
  final String name;
  final String unit;
  final double qty;
  final double price;
  final double total;
  final double returnedQty;
}

class Sale {
  const Sale({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paidCash,
    required this.paidCard,
    required this.debtAmount,
    required this.returnedTotal,
    required this.netTotal,
    required this.soldAt,
    this.customerId,
    this.customer,
    this.profit,
    this.itemsCount,
    this.items = const <SaleItem>[],
    this.note,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final Object? rawCustomer = json['customer'];
    final Object? rawItems = json['items'];

    return Sale(
      id: _asInt(json['id']),
      customerId: _asIntOrNull(json['customer_id']),
      customer: rawCustomer is Map
          ? Customer.fromJson(rawCustomer.cast<String, dynamic>())
          : null,
      status: json['status']?.toString() ?? 'completed',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      subtotal: _asDouble(json['subtotal']),
      discount: _asDouble(json['discount']),
      total: _asDouble(json['total']),
      paidCash: _asDouble(json['paid_cash']),
      paidCard: _asDouble(json['paid_card']),
      debtAmount: _asDouble(json['debt_amount']),
      profit: json['profit'] == null ? null : _asDouble(json['profit']),
      returnedTotal: _asDouble(json['returned_total']),
      netTotal: json['net_total'] == null
          ? _asDouble(json['total']) - _asDouble(json['returned_total'])
          : _asDouble(json['net_total']),
      itemsCount: _asIntOrNull(json['items_count']),
      items: rawItems is List
          ? rawItems
              .whereType<Map<Object?, Object?>>()
              .map((Map<Object?, Object?> it) =>
                  SaleItem.fromJson(it.cast<String, dynamic>()))
              .toList()
          : const <SaleItem>[],
      note: _asStringOrNull(json['note']),
      soldAt:
          DateTime.tryParse(json['sold_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  final int id;
  final int? customerId;
  final Customer? customer;

  /// completed | partially_returned | returned (backend `status`).
  final String status;

  /// cash | card | debt | mixed (backend `payment_method`).
  final String paymentMethod;
  final double subtotal;
  final double discount;
  final double total;
  final double paidCash;
  final double paidCard;
  final double debtAmount;
  final double? profit;
  final double returnedTotal;

  /// Qaytarishlar ayirilgan tushum.
  final double netTotal;
  final int? itemsCount;
  final List<SaleItem> items;
  final String? note;
  final DateTime soldAt;

  bool get hasReturns => returnedTotal > 0;
}

/// GET /sales/summary — default bugungi kun (dashboard kartalari uchun).
class SalesSummary {
  const SalesSummary({
    required this.salesCount,
    required this.returnsCount,
    required this.total,
    required this.returnedTotal,
    required this.netTotal,
    required this.discount,
    required this.profit,
    required this.cash,
    required this.card,
    required this.debt,
    required this.averageCheck,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      salesCount: _asInt(json['sales_count']),
      returnsCount: _asInt(json['returns_count']),
      total: _asDouble(json['total']),
      returnedTotal: _asDouble(json['returned_total']),
      netTotal: _asDouble(json['net_total']),
      discount: _asDouble(json['discount']),
      profit: _asDouble(json['profit']),
      cash: _asDouble(json['cash']),
      card: _asDouble(json['card']),
      debt: _asDouble(json['debt']),
      averageCheck: _asDouble(json['average_check']),
    );
  }

  final int salesCount;
  final int returnsCount;
  final double total;
  final double returnedTotal;
  final double netTotal;
  final double discount;
  final double profit;
  final double cash;
  final double card;
  final double debt;
  final double averageCheck;
}

/// GET /sales/{id}/receipt — elektron chek (TZ 16).
class SaleReceipt {
  const SaleReceipt({
    required this.text,
    this.lines = const <String>[],
    this.shopName,
    this.phone,
  });

  factory SaleReceipt.fromJson(Map<String, dynamic> json) {
    final Object? rawLines = json['lines'];
    final List<String> lines = rawLines is List
        ? rawLines.map((Object? it) => it?.toString() ?? '').toList()
        : const <String>[];

    return SaleReceipt(
      text: json['text']?.toString() ?? lines.join('\n'),
      lines: lines,
      shopName: _asStringOrNull(json['shop_name']),
      phone: _asStringOrNull(json['phone']),
    );
  }

  final String text;
  final List<String> lines;
  final String? shopName;
  final String? phone;
}
