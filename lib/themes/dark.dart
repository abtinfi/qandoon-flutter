import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.grey.shade900,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurpleAccent,
    brightness: Brightness.dark,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade800,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    prefixIconColor: Colors.deepPurpleAccent,
    suffixIconColor: Colors.deepPurpleAccent,
    labelStyle: TextStyle(color: Colors.white70),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: Colors.white30),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: Colors.redAccent, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurpleAccent,
      foregroundColor: Colors.white,
      fixedSize: const Size(280, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.deepPurpleAccent,
      textStyle: const TextStyle(fontSize: 14),
    ),
  ),
  appBarTheme: AppBarTheme(centerTitle: true),
);
