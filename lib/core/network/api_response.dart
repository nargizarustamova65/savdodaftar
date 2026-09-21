/// Backend javob konverti: `{ success, message, data }`.
class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'],
    );
  }

  final bool success;
  final String message;
  final Object? data;

  /// `data` obyekt bo'lsa map qaytaradi, aks holda bo'sh map.
  Map<String, dynamic> get dataMap {
    final Object? value = data;
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  /// `data` massiv bo'lsa ro'yxat qaytaradi.
  List<Map<String, dynamic>> get dataList {
    final Object? value = data;
    if (value is List) {
      return value
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> it) => it.cast<String, dynamic>())
          .toList();
    }
    return <Map<String, dynamic>>[];
  }
}
