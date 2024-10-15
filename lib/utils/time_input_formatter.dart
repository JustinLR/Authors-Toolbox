// time_input_formatter.dart
import 'package:flutter/services.dart';

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String oldText = oldValue.text;
    String newText = newValue.text;

    // Remove non-numeric characters from the input
    String digitsOnly = newText.replaceAll(RegExp(r'[^0-9]'), '');

    // We maintain the fixed format: HH:MM:SS
    String formattedTime = oldText;

    // Calculate the cursor position before formatting
    int cursorPosition = newValue.selection.start;

    // Limit input to a maximum of 6 digits (HHMMSS)
    if (digitsOnly.length > 6) {
      digitsOnly = digitsOnly.substring(0, 6);
    }

    // Handle formatting by replacing the numeric placeholders in the existing formatted time
    int digitIndex = 0;
    for (int i = 0; i < formattedTime.length; i++) {
      if (digitIndex < digitsOnly.length && i != 2 && i != 5) {
        formattedTime =
            formattedTime.replaceRange(i, i + 1, digitsOnly[digitIndex]);
        digitIndex++;
      }
    }

    // Adjust the cursor position to ensure it doesn't land on colons
    if (cursorPosition == 2 || cursorPosition == 5) {
      cursorPosition++;
    }

    // Ensure the cursor position stays within the formatted time
    cursorPosition = cursorPosition.clamp(0, formattedTime.length);

    return TextEditingValue(
      text: formattedTime,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
