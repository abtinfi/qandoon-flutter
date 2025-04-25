// providers/user_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  bool get isAuthenticated => _user != null;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  Future<void> logout() async {
    final _storage = const FlutterSecureStorage();
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (e) {
      print('Error deleting JWT token: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      print('User data deleted from SharedPreferences successfully.');
    } catch (e) {
      print('Error deleting user data from SharedPreferences: $e');
    }

    clearUser();

    print('User logged out from Provider state.');
  }
}
