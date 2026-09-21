import 'package:flutter/services.dart';

/// O'zbekiston telefon raqamlari bilan ishlash — TZ 37.1 (E.164).
abstract final class Phone {
  static const String countryCode = '+998';
  static const int nationalLength = 9;

  static String digitsOnly(String input) =>
      input.replaceAll(RegExp('[^0-9]'), '');

  /// Kiritilgan matndan faqat milliy qismni ajratadi (9 xona).
  ///
  /// `+998 90 123 45 67`, `998901234567`, `901234567` — hammasi
  /// `901234567` ga keltiriladi.
  static String national(String input) {
    String digits = digitsOnly(input);
    if (digits.startsWith('998') && digits.length > nationalLength) {
      digits = digits.substring(3);
    }
    if (digits.length > nationalLength) {
      digits = digits.substring(digits.length - nationalLength);
    }
    return digits;
  }

  static bool isValid(String input) => national(input).length == nationalLength;

  /// Backend uchun format: `+998901234567`.
  static String toE164(String input) => '$countryCode${national(input)}';

  /// Ko'rsatish uchun format: `90 123 45 67`.
  static String formatNational(String input) {
    final String digits = national(input);
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// To'liq ko'rsatish: `+998 90 123 45 67`.
  static String formatFull(String input) =>
      '$countryCode ${formatNational(input)}';
}

/// Kiritish paytida `90 123 45 67` ko'rinishiga keltiradi.
class PhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = Phone.national(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final String formatted = Phone.formatNational(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
