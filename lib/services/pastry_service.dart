import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pastry_model.dart';

class PastryService {
  static Future<List<Pastry>> fetchPastries() async {
    // final response = await http.get(Uri.parse('https://api.devnima.ir/pastries'));
    //
    // if (response.statusCode == 200) {
    //   final List<dynamic> data = jsonDecode(response.body);
    //   return data.map((json) => Pastry.fromJson(json)).toList();
    // } else {
    //   throw Exception('Failed to load pastries');
    // }
    await Future.delayed(Duration(seconds: 1)); // شبیه‌سازی تاخیر شبکه
    String x = 'https://dicardo.com/Uploads/shopproducts/7677/original-401a8eaa-99bc-4053-98ff-14949b734d18.jpg';
    final List<dynamic> data = [
      {
        'name': 'Chocolate Cake',
        'description': 'Rich and creamy chocolate layered cake',
        'image': x,
        'price': 85000,
      },
      {
        'name': 'Strawberry Tart',
        'description': 'Crispy tart filled with custard and fresh strawberries',
        'image': x,
        'price': 75000,
      },
      {
        'name': 'French Macarons',
        'description': 'Colorful macarons with a variety of flavors',
        'image': x,
        'price': 60000,
      },
      {
        'name': 'Baklava',
        'description': 'Traditional Middle Eastern pastry with honey and nuts',
        'image': x,
        'price': 90000,
      },
    ];

    return data.map((json) => Pastry.fromJson(json)).toList();
  }

}