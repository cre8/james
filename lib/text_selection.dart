import 'package:flutter/services.dart';

class TextSelection2 {
  static const platform = MethodChannel('com.example.text_selection');

  static Future<String?> getSelectedText() async {
    try {
      final selectedText =
          await platform.invokeMethod<String>('getSelectedText');
      return selectedText;
    } catch (e) {
      print('Failed to get selected text: $e');
      return null;
    }
  }
}
