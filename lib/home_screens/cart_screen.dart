import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../providers/user_provider.dart';
import '../widget/login_required_dialog.dart';
import '../screens/authentication/login/login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  bool _dialogShown = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(CartProvider cart) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isAuthenticated) {
      if (!_dialogShown) {
        _dialogShown = true;
        final result = await showLoginRequiredDialog(context);
        if (result == 'login' && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        _dialogShown = false;
      }
      return;
    }
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      _showSnackBar('Please enter address and phone number.');
      return;
    }

    if (cart.items.isEmpty) {
      _showSnackBar('Your cart is empty.');
      return;
    }

    final order = OrderCreateModel(
      address: _addressController.text,
      phoneNumber: _phoneController.text,
      items: cart.getOrderItems(),
    );

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _showSnackBar('Please login to place an order.', isError: true);
        return;
      }

      await OrderService.createOrder(order);
      cart.clearCart();

      _showSnackBar('Order placed successfully.', isSuccess: true);

      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(message.isNotEmpty ? message : 'Failed to submit order.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red : isSuccess ? Colors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (cartItems.isEmpty)
              const Expanded(child: Center(child: Text('Your cart is empty.')))
            else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItem(item, cart);
                  },
                ),
              ),
              _buildOrderForm(cart),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(cartItem, CartProvider cart) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: cartItem.pastry.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.pastry.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cartItem.pastry.price.toStringAsFixed(0)} Toman',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.numbers, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${cartItem.quantity} pcs',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  )
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
              onPressed: () => cart.removeFromCart(cartItem.pastry.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderForm(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submitOrder(cart),
          child: _isSubmitting
              ? const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          )
              : const Text('Submit Order'),
        ),
      ],
    );
  }

}
