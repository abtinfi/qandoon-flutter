// updated_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder:
                (context, url) =>
                    const CircularProgressIndicator(color: Colors.white),
            errorWidget:
                (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 60,
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
    } catch (_) {
      setState(() => _isAdmin = false);
    }
  }

  Future<void> _editPastry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPastryScreen(pastry: widget.pastry),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastry updated successfully.')),
      );
    }
  }

  Future<void> _deletePastry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Pastry'),
            content: const Text('Are you sure you want to delete this pastry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final res = await http.delete(
        Uri.parse('https://api.abtinfi.ir/pastries/${widget.pastry.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 204 && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pastry deleted.')));
        Navigator.pop(context, true);
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: 4{e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pastry = widget.pastry;

    return Scaffold(
      appBar: AppBar(
        title: Text(pastry.name),
        actions:
            _isAdmin
                ? [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _editPastry,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deletePastry,
                  ),
                ]
                : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: pastry.imageUrl,
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                FullScreenImageView(imageUrl: pastry.imageUrl),
                      ),
                    ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: pastry.imageUrl,
                    fit: BoxFit.cover,
                    height: 250,
                    width: double.infinity,
                    placeholder:
                        (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
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
            Text(
              pastry.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 100),
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
                  'Price: ${pastry.price.toStringAsFixed(0)} Toman',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Stock: ${pastry.stock}',
                  style: const TextStyle(fontSize: 16, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity:', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_quantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      onPressed: () {
                        if (_quantity < pastry.stock)
                          setState(() => _quantity++);
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
                  final cart = Provider.of<CartProvider>(
                    context,
                    listen: false,
                  );
                  cart.addToCart(pastry, _quantity);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$_quantity × "${pastry.name}" added to cart.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text('Add $_quantity to Cart'),
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
