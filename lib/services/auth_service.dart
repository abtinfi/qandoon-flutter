import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _meEndpoint = 'https://api.abtinfi.ir/users/me';

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> clearAuthData() async {
    await _storage.delete(key: 'jwt_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  static Future<UserModel?> fetchUser(String token) async {
    final response = await http.get(
      Uri.parse(_meEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return UserModel.fromJson(responseBody);
    } else if (response.statusCode == 401) {
      throw AuthException.unauthorized();
    } else {
      throw AuthException.unknown();
    }
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  factory AuthException.unauthorized() => AuthException('Unauthorized');
  factory AuthException.unknown() => AuthException('Unknown error');
}
