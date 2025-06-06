import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pastry_model.dart';
import '../providers/cart_provider.dart';
import 'edit_pastry_screen.dart';

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PastryDetailScreen extends StatefulWidget {
  final Pastry pastry;

  const PastryDetailScreen({super.key, required this.pastry});

  @override
  State<PastryDetailScreen> createState() => _PastryDetailScreenState();
}

class _PastryDetailScreenState extends State<PastryDetailScreen> {
  int _quantity = 1;
  bool _isAdmin = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final userJson = await _storage.read(key: 'user');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        setState(() {
          _isAdmin = userData['is_admin'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _editPastry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPastryScreen(pastry: widget.pastry),
      ),
    );

    if (result == true) {
      // Refresh the pastry data if needed
      // You might want to implement a refresh mechanism here
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اطلاعات شیرینی با موفقیت بروزرسانی شد')),
        );
      }
    }
  }

  Future<void> _deletePastry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف شیرینی'),
        content: const Text('آیا از حذف این شیرینی اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.delete(
        Uri.parse('https://api.abtinfi.ir/pastries/${widget.pastry.id}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شیرینی با موفقیت حذف شد')),
        );
        Navigator.pop(context, true); // Return to previous screen
      } else {
        throw Exception('خطا در حذف شیرینی: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pastry = widget.pastry;

    return Scaffold(
      appBar: AppBar(
        title: Text(pastry.name),
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editPastry,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deletePastry,
                  color: Colors.red,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: pastry.imageUrl,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageView(
                        imageUrl: pastry.imageUrl,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 250,
                    child: CachedNetworkImage(
                      imageUrl: pastry.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        height: 250,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              pastry.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      pastry.description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 100), // برای اینکه محتوا پشت دکمه پایین نره
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'قیمت: ${pastry.price.toStringAsFixed(0)} تومان',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'موجودی: ${pastry.stock}',
                  style: const TextStyle(fontSize: 16, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تعداد:', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() {
                            _quantity--;
                          });
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_quantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      onPressed: () {
                        if (_quantity < pastry.stock) {
                          setState(() {
                            _quantity++;
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  cart.addToCart(pastry, _quantity);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$_quantity عدد "${pastry.name}" به سبد خرید اضافه شد.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text('افزودن $_quantity عدد به سبد خرید'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
