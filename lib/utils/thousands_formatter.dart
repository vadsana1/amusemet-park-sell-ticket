import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final intValue = int.tryParse(newValue.text.replaceAll(',', ''));
    if (intValue == null) {
      return oldValue;
    }
    final formatter = NumberFormat('#,##0', 'en_US');
    String newText = formatter.format(intValue);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
