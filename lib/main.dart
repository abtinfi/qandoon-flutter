// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/theme_controller.dart';
import 'app.dart';
import 'providers/user_provider.dart'; // اضافه کردن UserProvider
import 'screens/authentication/auth_check_screen.dart'; // اضافه کردن صفحه چک احراز هویت

void main() {
  runApp(
    // استفاده از MultiProvider برای اضافه کردن چندین Provider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => UserProvider()), // اضافه کردن UserProvider
      ],
      child: const MyApp(),
    ),
  );
}