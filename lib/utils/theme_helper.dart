// utils/theme_helper.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final log = Logger();
Future<void> saveThemeColor(MaterialColor color) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('themeColor', color.value);
  await prefs.setInt('themeColor-shade50', color.shade50.value);
  await prefs.setInt('themeColor-shade100', color.shade100.value);
  await prefs.setInt('themeColor-shade200', color.shade200.value);
  await prefs.setInt('themeColor-shade300', color.shade300.value);
  await prefs.setInt('themeColor-shade400', color.shade400.value);
  await prefs.setInt('themeColor-shade500', color.shade500.value);
  await prefs.setInt('themeColor-shade600', color.shade600.value);
  await prefs.setInt('themeColor-shade700', color.shade700.value);
  await prefs.setInt('themeColor-shade800', color.shade800.value);
  await prefs.setInt('themeColor-shade900', color.shade900.value);
}

Future<MaterialColor> loadThemeColor() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getInt('themeColor') == null) {
    return Colors.lightGreen;
  }
  int colorValue = prefs.getInt('themeColor') ?? Colors.lightGreen.value;
  Map<int, Color> colorSwatch = {
    50: Color(prefs.getInt('themeColor-shade50') ?? 0),
    100: Color(prefs.getInt('themeColor-shade100') ?? 0),
    200: Color(prefs.getInt('themeColor-shade200') ?? 0),
    300: Color(prefs.getInt('themeColor-shade300') ?? 0),
    400: Color(prefs.getInt('themeColor-shade400') ?? 0),
    500: Color(prefs.getInt('themeColor-shade500') ?? 0),
    600: Color(prefs.getInt('themeColor-shade600') ?? 0),
    700: Color(prefs.getInt('themeColor-shade700') ?? 0),
    800: Color(prefs.getInt('themeColor-shade800') ?? 0),
    900: Color(prefs.getInt('themeColor-shade900') ?? 0),
  };
  return MaterialColor(Color(colorValue).value, colorSwatch);
  // return createMaterialColor(Color(colorValue));
}
