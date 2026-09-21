/// Ombor moduli modellari — TZ 11–12 va 28-bo'lim (`products`,
/// `stock_movements`).
library;

/// Backend `Product::UNITS` bilan bir xil tartibda.
const List<String> productUnits = <String>[
  'dona',
  'kg',
  'g',
  'litr',
  'metr',
  'm2',
  'qop',
  'quti',
  'pachka',
  'juft',
  'komplekt',
  'boshqa',
];

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

/// Miqdorni chiroyli ko'rsatadi: `3` yoki `2.5` (ortiqcha nollarsiz).
String formatQty(num qty) {
  if (qty == qty.roundToDouble()) {
    return qty.round().toString();
  }
  String text = qty.toStringAsFixed(3);
  while (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.sellPrice,
    required this.stock,
    required this.minStock,
    required this.stockStatus,
    this.category,
    this.barcode,
    this.buyPrice,
    this.marginPercent,
    this.isLowStock = false,
    this.stockValue,
    this.imageUrl,
    this.isActive = true,
    this.movements = const <StockMovementItem>[],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final Object? rawMovements = json['movements'];

    return Product(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      category: _asStringOrNull(json['category']),
      barcode: _asStringOrNull(json['barcode']),
      unit: json['unit']?.toString() ?? 'dona',
      buyPrice:
          json['buy_price'] == null ? null : _asDouble(json['buy_price']),
      sellPrice: _asDouble(json['sell_price']),
      marginPercent: json['margin_percent'] == null
          ? null
          : _asDouble(json['margin_percent']),
      stock: _asDouble(json['stock']),
      minStock: _asDouble(json['min_stock']),
      stockStatus: json['stock_status']?.toString() ?? 'ok',
      isLowStock: json['is_low_stock'] == true,
      stockValue:
          json['stock_value'] == null ? null : _asDouble(json['stock_value']),
      imageUrl: _asStringOrNull(json['image_url']),
      isActive: json['is_active'] != false,
      movements: rawMovements is List
          ? rawMovements
              .whereType<Map<Object?, Object?>>()
              .map((Map<Object?, Object?> it) =>
                  StockMovementItem.fromJson(it.cast<String, dynamic>()))
              .toList()
          : const <StockMovementItem>[],
    );
  }

  final int id;
  final String name;
  final String? category;
  final String? barcode;
  final String unit;
  final double? buyPrice;
  final double sellPrice;
  final double? marginPercent;
  final double stock;
  final double minStock;

  /// ok | low | out (backend `stock_status`).
  final String stockStatus;
  final bool isLowStock;
  final double? stockValue;
  final String? imageUrl;
  final bool isActive;
  final List<StockMovementItem> movements;

  bool get isOut => stockStatus == 'out';
}

class StockMovementItem {
  const StockMovementItem({
    required this.id,
    required this.type,
    required this.isIncoming,
    required this.qty,
    required this.stockAfter,
    required this.createdAt,
    this.buyPrice,
    this.note,
  });

  factory StockMovementItem.fromJson(Map<String, dynamic> json) {
    return StockMovementItem(
      id: _asInt(json['id']),
      type: json['type']?.toString() ?? '',
      isIncoming: json['direction']?.toString() == 'plus',
      qty: _asDouble(json['qty']),
      stockAfter: _asDouble(json['stock_after']),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      buyPrice:
          json['buy_price'] == null ? null : _asDouble(json['buy_price']),
      note: _asStringOrNull(json['note']),
    );
  }

  final int id;
  final String type;
  final bool isIncoming;
  final double qty;
  final double stockAfter;
  final DateTime createdAt;
  final double? buyPrice;
  final String? note;
}

/// GET /products/summary.
class ProductsSummary {
  const ProductsSummary({
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.attentionCount,
    required this.stockValue,
    required this.potentialRevenue,
  });

  factory ProductsSummary.fromJson(Map<String, dynamic> json) {
    return ProductsSummary(
      totalProducts: _asInt(json['total_products']),
      lowStockCount: _asInt(json['low_stock_count']),
      outOfStockCount: _asInt(json['out_of_stock_count']),
      attentionCount: _asInt(json['attention_count']),
      stockValue: _asDouble(json['stock_value']),
      potentialRevenue: _asDouble(json['potential_revenue']),
    );
  }

  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final int attentionCount;
  final double stockValue;
  final double potentialRevenue;
}
