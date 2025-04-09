import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/theme_controller.dart';

AppBar appBar(BuildContext context) {
  final themeController = Provider.of<ThemeController>(context);

  return AppBar(
    title: Text('Bakery'),
    actions: [
      IconButton(
        icon: Icon(
          themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        ),
        onPressed: () => themeController.toggleTheme(),
      ),
    ],
  );
}
