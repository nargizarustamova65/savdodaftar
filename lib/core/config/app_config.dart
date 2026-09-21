/// Ilova muhiti konfiguratsiyasi.
///
/// Base URL'ni build vaqtida almashtirish mumkin:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`
///
/// Android emulyatorda lokal backend uchun `10.0.2.2`,
/// iOS simulyatorda `127.0.0.1` ishlatiladi.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://abdullohinfo.uz/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// OTP qayta yuborish tugmasi faollashadigan standart interval
  /// (backend `resend_after` qaytarmasa ishlatiladi) — TZ 37.2.
  static const int defaultOtpResendSeconds = 45;

  /// PIN uzunligi — TZ 7-bo'lim.
  static const int pinLength = 4;

  /// OTP kod uzunligi — TZ 6-bo'lim.
  static const int otpLength = 6;
}
