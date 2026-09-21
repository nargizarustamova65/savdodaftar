/// Backend qaytargan xatolikning yagona ko'rinishi.
///
/// savdodaftar-backend formati:
/// `{ "success": false, "message": "...", "code": "otp_invalid", "meta": { } }`
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.meta = const <String, dynamic>{},
  });

  final String message;

  /// Backend kodi: `otp_invalid`, `otp_expired`, `pin_blocked`, ...
  final String? code;

  final int? statusCode;

  /// Qo'shimcha ma'lumot, masalan `{ "attempts_left": 3 }`.
  final Map<String, dynamic> meta;

  /// Tarmoq uzilishi — offline holatni aniqlash uchun.
  bool get isNetwork => code == _networkCode;

  bool get isUnauthenticated =>
      statusCode == 401 || code == 'unauthenticated';

  /// Noto'g'ri urinishlardan keyin qolgan imkoniyat soni.
  int? get attemptsLeft {
    final Object? value = meta['attempts_left'];
    return value is int ? value : int.tryParse(value?.toString() ?? '');
  }

  static const String _networkCode = 'network_error';

  factory ApiException.network(String message) =>
      ApiException(message: message, code: _networkCode);

  @override
  String toString() => 'ApiException(${code ?? statusCode}): $message';
}
