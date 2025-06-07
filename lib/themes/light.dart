import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFFF8F4), // کرم روشن، حس شیرینی و لطافت
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFE87A5D), // صورتی کاراملی
    secondary: Color(0xFFA66547), // قهوه‌ای روشن
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFF4A2F26), // قهوه‌ای شکلاتی تیره
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF5C3B31),
    ),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF7C5B53)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFFFFFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    prefixIconColor: const Color(0xFFE87A5D),
    suffixIconColor: const Color(0xFFE87A5D),
    labelStyle: const TextStyle(color: Color(0xFF7C5B53)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFFDDB9A0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFFE87A5D), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE87A5D),
      foregroundColor: Colors.white,
      fixedSize: const Size(280, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFE87A5D),
      textStyle: const TextStyle(fontSize: 14),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFF0E5),
    foregroundColor: Color(0xFF4A2F26),
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFF4A2F26),
    ),
    iconTheme: IconThemeData(color: Color(0xFFE87A5D)),
  ),
);
