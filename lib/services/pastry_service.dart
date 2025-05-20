import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pastry_model.dart';

class PastryService {
  static const String _baseUrl = 'https://api.abtinfi.ir';

  static Future<List<Pastry>> fetchPastries() async {
    final response = await http.get(Uri.parse('$_baseUrl/pastries'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Pastry.fromJson(json)).toList();
    } else {
      throw Exception('خطا در دریافت لیست شیرینی‌ها');
    }
  }
}
