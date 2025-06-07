import 'package:flutter/material.dart';

Future<String?> showLoginRequiredDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to log in to access this section.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Login'),
            onPressed: () {
              Navigator.of(context).pop('login');
            },
          ),
        ],
      );
    },
  );
}
