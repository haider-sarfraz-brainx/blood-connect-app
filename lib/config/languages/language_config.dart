import 'package:flutter/material.dart';

import '../config.dart';
import 'language.dart';
class LanguageConfig {
  static final List<String> _keys = [
    Config.english,
    Config.urdu,
  ];

  static final Map<String, Locale> _locales = {
    Config.english: Locale('en', 'US'),
    Config.urdu: Locale('ur', 'PK'),
  };

  static const Map<String, String> _labels = {
    Config.english: "English",
    Config.urdu: "اردو",
  };

  static Language defaultLanguage(key) =>
      Language(name: _labels[key]!, locale: _locales[key]!);

  static List<Language> get languages => _keys
      .map((key) => Language(name: _labels[key]!, locale: _locales[key]!))
      .toList();
  static List<Locale> get locales => _locales.values.toList();
}
