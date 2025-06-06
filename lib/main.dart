import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/theme_controller.dart';
import 'app.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}