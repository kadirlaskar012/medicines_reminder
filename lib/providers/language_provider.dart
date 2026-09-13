import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language_code';
  String _languageCode = 'en';

  LanguageProvider() {
    _loadLanguage();
  }

  String get languageCode => _languageCode;
  AppStrings get strings => AppStrings.of(_languageCode);

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && (saved == 'en' || saved == 'bn' || saved == 'hi')) {
        _languageCode = saved;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }
}
