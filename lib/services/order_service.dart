import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/order_model.dart';

class OrderService {
  static const _fetchEndpoint = 'https://api.abtinfi.ir/order/orders';
  static const _createEndpoint = 'https://api.abtinfi.ir/order/new';
  static const _storage = FlutterSecureStorage();

  /// گرفتن لیست سفارش‌ها
  static Future<List<OrderModel>> fetchOrders() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse(_fetchEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  /// ثبت سفارش جدید
  static Future<void> createOrder(OrderCreateModel order) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('لطفاً ابتدا وارد حساب کاربری خود شوید');

    try {
      final response = await http.post(
        Uri.parse(_createEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(order.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('زمان اتصال به سرور به پایان رسید. لطفاً دوباره تلاش کنید');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      String errorMessage = 'خطا در ثبت سفارش';
      try {
        final responseBody = jsonDecode(response.body);
        if (responseBody != null) {
          if (responseBody['detail'] != null) {
            errorMessage = responseBody['detail'];
          } else if (responseBody['message'] != null) {
            errorMessage = responseBody['message'];
          }
        }
      } catch (e) {
        // If JSON parsing fails, use the raw response body
        errorMessage = response.body;
      }
      
      throw Exception(errorMessage);
    } on http.ClientException catch (e) {
      throw Exception('خطا در اتصال به سرور. لطفاً اتصال اینترنت خود را بررسی کنید');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('خطا در ارتباط با سرور. لطفاً دوباره تلاش کنید');
    }
  }
}
