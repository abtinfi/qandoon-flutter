import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitOrder(CartProvider cart) async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً آدرس و شماره تماس را وارد کنید')),
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سبد خرید خالی است')),
      );
      return;
    }

    final order = OrderCreateModel(
      address: _addressController.text,
      phoneNumber: _phoneController.text,
      items: cart.getOrderItems(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً ابتدا وارد حساب کاربری خود شوید'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await OrderService.createOrder(order);
      
      if (!mounted) return;
      cart.clearCart();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سفارش با موفقیت ثبت شد'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to home screen
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'خطا در ثبت سفارش';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('سبد خرید')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (cart.items.isEmpty)
              const Expanded(child: Center(child: Text('سبد خرید خالی است')))
            else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items.values.toList()[index];
                    return ListTile(
                      title: Text('شیرینی #${item.pastryId}'),
                      subtitle: Text('تعداد: ${item.quantity}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => cart.removeFromCart(item.pastryId),
                      ),
                    );
                  },
                ),
              ),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'آدرس'),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'شماره تماس'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitOrder(cart),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('ثبت سفارش'),
              )
            ],
          ],
        ),
      ),
    );
  }
}
