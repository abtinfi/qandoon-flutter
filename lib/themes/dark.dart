import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1B100A), // شکلاتی خیلی تیره
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFD67D3E), // کاراملی گرم برای تاکید
    secondary: Color(0xFFA65C32), // قهوه‌ای روشن‌تر
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFFF1E6), // کرم روشن
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFFF5DCC2),
    ),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFD3BBA0)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2E1F14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    prefixIconColor: const Color(0xFFD67D3E),
    suffixIconColor: const Color(0xFFD67D3E),
    labelStyle: const TextStyle(color: Color(0xFFD3BBA0)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFF6F4E37)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFFD67D3E), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD67D3E),
      foregroundColor: Colors.white,
      fixedSize: const Size(280, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFD67D3E),
      textStyle: const TextStyle(fontSize: 14),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1B100A),
    centerTitle: true,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 20,
      color: Color(0xFFFFF1E6),
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: Color(0xFFD67D3E)),
  ),
);
