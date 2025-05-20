import 'package:flutter/material.dart';
import '../models/pastry_model.dart';
import '../models/order_model.dart';

class CartProvider with ChangeNotifier {
  final Map<int, OrderItem> _items = {}; // key: pastryId

  Map<int, OrderItem> get items => _items;

  void addToCart(Pastry pastry, int quantity) {
    if (_items.containsKey(pastry.id)) {
      _items[pastry.id] = OrderItem(
        pastryId: pastry.id,
        quantity: _items[pastry.id]!.quantity + quantity,
      );
    } else {
      _items[pastry.id] = OrderItem(
        pastryId: pastry.id,
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
      _items[pastryId] = OrderItem(pastryId: pastryId, quantity: quantity);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  List<OrderItem> getOrderItems() {
    return _items.values.toList();
  }

  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);
}
