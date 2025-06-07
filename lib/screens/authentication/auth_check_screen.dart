import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../home_screens/home_screen.dart';
import 'login/login_screen.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthStatus());
  }

  Future<void> _checkAuthStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final token = await AuthService.getToken();

    if (token == null) {
      // Go to HomeScreen (shop) even if not logged in
      _navigateToHome();
      return;
    }

    try {
      final user = await AuthService.fetchUser(token);
      userProvider.setUser(user!);
      await prefs.setString('user_data', user.toJsonString());
      _navigateToHome();
    } on AuthException catch (_) {
      await AuthService.clearAuthData();
      userProvider.clearUser();
      _navigateToHome();
    } catch (_) {
      await AuthService.clearAuthData();
      userProvider.clearUser();
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
