import '../l10n/app_strings.dart';
import 'api_exception.dart';

/// Backend xatoligini foydalanuvchi tiliga o'giradi.
///
/// Backend `Accept-Language` bo'yicha `message` ni allaqachon tarjima qilib
/// qaytaradi, shuning uchun uni bevosita ko'rsatamiz. Faqat tarmoq va
/// noma'lum xatoliklar uchun lokal matn ishlatiladi.
String apiErrorText(AppStrings s, Object error) {
  if (error is! ApiException) {
    return s.errorUnknown;
  }
  if (error.isNetwork) {
    return s.errorNetwork;
  }
  final String message = error.message.trim();
  if (message.isEmpty ||
      error.code == 'unknown_error' ||
      error.code == 'invalid_response') {
    return s.errorUnknown;
  }
  return message;
}
