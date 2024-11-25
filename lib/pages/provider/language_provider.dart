import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  String _languageCode = 'en'; // Default ke bahasa Inggris

  String get languageCode => _languageCode;

  void setLanguage(String code) {
    _languageCode = code;
    notifyListeners(); // Memberitahukan perubahan kepada widget yang mendengarkan
  }
}
