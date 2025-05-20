import 'package:flutter/material.dart';
import '../models/pastry_model.dart';
import '../models/order_model.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {}; // key: pastryId

  Map<int, CartItem> get items => _items;

  void addToCart(Pastry pastry, int quantity) {
    if (_items.containsKey(pastry.id)) {
      _items[pastry.id] = CartItem(
        pastry: pastry,
        quantity: _items[pastry.id]!.quantity + quantity,
      );
    } else {
      _items[pastry.id] = CartItem(
        pastry: pastry,
        quantity: quantity,
      );
    }
    notifyListeners();
  }

  void removeFromCart(int pastryId) {
    _items.remove(pastryId);
    notifyListeners();
  }

  void updateQuantity(int pastryId, int quantity) {
    if (_items.containsKey(pastryId)) {
      _items[pastryId] = CartItem(
        pastry: _items[pastryId]!.pastry,
        quantity: quantity,
      );
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  List<OrderItem> getOrderItems() {
    return _items.values.map((item) => OrderItem(
      pastryId: item.pastry.id,
      quantity: item.quantity,
    )).toList();
  }

  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);
}

class CartItem {
  final Pastry pastry;
  final int quantity;

  CartItem({
    required this.pastry,
    required this.quantity,
  });
}
