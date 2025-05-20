import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import 'detail_screen.dart';

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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PastryDetailScreen(
                                pastry: item.pastry,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item.pastry.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          title: Text(
                            item.pastry.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'قیمت: ${item.pastry.price.toStringAsFixed(0)} تومان',
                            style: const TextStyle(color: Colors.green),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.quantity} عدد',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => cart.removeFromCart(item.pastry.id),
                              ),
                            ],
                          ),
                        ),
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
