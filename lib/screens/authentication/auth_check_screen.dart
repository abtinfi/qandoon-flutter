import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home_screens/home_screen.dart';
import 'login/login_screen.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _storage = const FlutterSecureStorage();
  final String _meEndpoint = 'https://api.abtinfi.ir/users/me';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null) {
      _navigateToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(_meEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final user = UserModel.fromJson(responseBody);

        userProvider.setUser(user);
        await prefs.setString('user_data', jsonEncode(user.toJson()));

        _navigateToHome();
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        await prefs.remove('user_data');

        userProvider.clearUser();
        _navigateToLogin();
      } else {
        await _storage.delete(key: 'jwt_token');
        await prefs.remove('user_data');
        userProvider.clearUser();
        _navigateToLogin();
      }
    } catch (e) {
      await _storage.delete(key: 'jwt_token');
      await prefs.remove('user_data');
      userProvider.clearUser();
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
