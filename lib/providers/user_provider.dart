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
    await _clearSecureStorage();
    await _clearPreferences();
    clearUser();
    debugPrint('User logged out and all cached data cleared.');
  }

  Future<void> _clearSecureStorage() async {
    const storage = FlutterSecureStorage();
    try {
      await storage.deleteAll();
      debugPrint('Secure storage cleared.');
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
    }
  }

  Future<void> _clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('Shared preferences cleared.');
    } catch (e) {
      debugPrint('Error clearing preferences: $e');
    }
  }
}
