/// Pul summalarini TZ formatida ko'rsatish va o'qish: `150 000 so'm`.
///
/// Ming ajratuvchi sifatida uzilmas bo'sh joy (NBSP) ishlatiladi — shunda
/// summa satr oxirida ikkiga bo'linib ketmaydi.
abstract final class Money {
  static const String currency = "so'm";
  static const String nbsp = '\u00A0';
  static const String _minus = '\u2212';

  /// Faqat raqamlarni guruhlaydi: `150000` -> `150 000`.
  static String group(num amount) {
    final bool isNegative = amount < 0;
    final String digits = amount.abs().round().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(nbsp);
      }
      buffer.write(digits[i]);
    }

    return isNegative ? '$_minus$buffer' : buffer.toString();
  }

  /// To'liq format: `150 000 so'm`.
  ///
  /// [signed] true bo'lsa musbat summa oldiga `+` qo'yiladi (qarz tarixi uchun).
  static String format(
    num amount, {
    bool withCurrency = true,
    bool signed = false,
  }) {
    final String sign = signed && amount > 0 ? '+' : '';
    final String value = '$sign${group(amount)}';
    return withCurrency ? '$value$nbsp$currency' : value;
  }

  /// Foydalanuvchi kiritgan matndan butun summani ajratadi.
  static int parse(String text) {
    final String digits = text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) {
      return 0;
    }
    final String safe = digits.length > 15 ? digits.substring(0, 15) : digits;
    return int.tryParse(safe) ?? 0;
  }

  /// Marja foizi: sotuv va tannarx asosida (mahsulot qo'shish ekrani uchun).
  static double marginPercent({required num buyPrice, required num sellPrice}) {
    if (buyPrice <= 0) {
      return 0;
    }
    return ((sellPrice - buyPrice) / buyPrice) * 100;
  }
}
