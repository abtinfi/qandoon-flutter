import 'package:flutter/material.dart';
import '../models/pastry_model.dart';
import '../models/order_model.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(Pastry pastry, int quantity) {
    if (_items.containsKey(pastry.id)) {
      _items[pastry.id] = _items[pastry.id]!.copyWith(
        quantity: _items[pastry.id]!.quantity + quantity,
      );
    } else {
      _items[pastry.id] = CartItem(pastry: pastry, quantity: quantity);
    }
    notifyListeners();
  }

  void removeFromCart(int pastryId) {
    _items.remove(pastryId);
    notifyListeners();
  }

  void updateQuantity(int pastryId, int quantity) {
    if (_items.containsKey(pastryId)) {
      _items[pastryId] = _items[pastryId]!.copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  List<OrderItem> getOrderItems() {
    return _items.values.map((item) {
      return OrderItem(
        pastryId: item.pastry.id,
        quantity: item.quantity,
      );
    }).toList();
  }
}

class CartItem {
  final Pastry pastry;
  final int quantity;

  CartItem({required this.pastry, required this.quantity});

  CartItem copyWith({Pastry? pastry, int? quantity}) {
    return CartItem(
      pastry: pastry ?? this.pastry,
      quantity: quantity ?? this.quantity,
    );
  }
}
