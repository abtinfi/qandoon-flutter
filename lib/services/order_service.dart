import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/order_model.dart';
import '../models/pastry_model.dart';

class OrderService {
  static const _baseUrl = 'https://api.abtinfi.ir';
  static const _storage = FlutterSecureStorage();

  static Future<String> _getToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Authentication token not found');
    return token;
  }

  /// Fetch all orders
  static Future<List<OrderModel>> fetchOrders() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/order/orders'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch orders');
    }
  }

  /// Fetch a single pastry details
  static Future<Pastry> fetchPastryDetails(int pastryId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/pastries/$pastryId'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Pastry.fromJson(data);
    } else {
      throw Exception('Failed to fetch pastry details');
    }
  }

  /// Fetch order details + related pastries
  static Future<Map<String, dynamic>> fetchOrderDetails(int orderId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/order/orders/$orderId'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final order = OrderModel.fromJson(data);

      final pastries = await Future.wait(
        order.items.map((item) => fetchPastryDetails(item.pastryId)),
      );

      return {
        'order': order,
        'pastries': pastries,
      };
    } else {
      throw Exception('Failed to fetch order details');
    }
  }

  /// Create a new order
  static Future<void> createOrder(OrderCreateModel order) async {
    final token = await _getToken();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/order/new'),
        headers: _headers(token),
        body: jsonEncode(order.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out. Please try again.'),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_parseErrorMessage(response.body) ?? 'Failed to create order');
      }
    } on http.ClientException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      throw Exception('Unexpected error. Please try again.');
    }
  }

  /// Update order status
  static Future<void> updateOrderStatus(
      int orderId, {
        required String status,
        String? adminMessage,
      }) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$_baseUrl/order/orders/$orderId'),
      headers: _headers(token),
      body: jsonEncode({
        'status': status,
        if (adminMessage != null) 'admin_message': adminMessage,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order status');
    }
  }

  /// Helper: Auth headers
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  /// Helper: Try to parse meaningful error messages
  static String? _parseErrorMessage(String responseBody) {
    try {
      final body = jsonDecode(responseBody);
      if (body is Map<String, dynamic>) {
        return body['detail'] ?? body['message'];
      }
    } catch (_) {}
    return null;
  }
}
