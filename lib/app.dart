import 'package:bakery/home_screens/home_screen.dart';
import 'package:bakery/screens/authentication/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/themes/dark.dart';
import 'themes/light.dart';
import 'themes/theme_controller.dart';

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
      home: const LoginScreen(),
    );
  }
}
