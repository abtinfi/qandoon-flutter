import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/themes/dark.dart';
import 'themes/light.dart';
import 'themes/theme_controller.dart';
import 'screens/authentication/auth_check_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeController.currentThemeMode,
      home: const AuthCheckScreen(),
    );
  }
}