import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const _kThemeKey = 'app_theme_index';
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final ValueNotifier<int> themeIndex = ValueNotifier<int>(0);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_kThemeKey) ?? 0;
    themeIndex.value = idx;
  }

  Future<void> setTheme(int idx) async {
    themeIndex.value = idx;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeKey, idx);
  }

  static ThemeData themeDataForIndex(int idx, {bool useMaterial3 = true}) {
    final Color seed;
    switch (idx) {
      case 1:
        seed = Colors.indigo;
        break;
      case 2:
        seed = Colors.deepOrange;
        break;
      case 3:
        seed = Colors.pink;
        break;
      case 4:
        seed = Colors.green;
        break;
      case 5:
        seed = Colors.blueGrey;
        break;
      default:
        seed = Colors.teal;
    }
    return ThemeData(
      useMaterial3: useMaterial3,
      colorSchemeSeed: seed,
    );
  }
}
