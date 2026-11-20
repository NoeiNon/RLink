import 'package:flutter/services.dart';

/// Angka saja, otomatis diberi titik ribuan (21000 -> 21.000), maks 9 digit.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) digits = digits.substring(0, 9);
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// "2.100.000" -> 2100000 (0 kalau kosong atau tidak valid).
int parseMoney(String text) => int.tryParse(text.replaceAll('.', '')) ?? 0;
