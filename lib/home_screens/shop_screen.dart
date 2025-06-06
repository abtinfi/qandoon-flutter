import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/pastry_model.dart';
import '../models/user_model.dart';
import '../services/pastry_service.dart';
import 'add_pastry_screen.dart';
import 'detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _storage = const FlutterSecureStorage();
  late Future<List<Pastry>> _pastriesFuture;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchPastries();
    _checkAdminStatus();
  }

  void _fetchPastries() {
    _pastriesFuture = PastryService.fetchPastries();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final userJson = await _storage.read(key: 'user');
      if (userJson == null) return;

      final userMap = json.decode(userJson);
      final user = UserModel.fromJson(userMap);

      setState(() {
        _isAdmin = user.isAdmin;
      });
    } catch (_) {
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _refreshPastries() async {
    setState(() {
      _fetchPastries();
    });
    await _pastriesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فروشگاه')),
      body: FutureBuilder<List<Pastry>>(
        future: _pastriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطا: ${snapshot.error}'));
          }

          final pastries = snapshot.data ?? [];

          if (pastries.isEmpty) {
            return const Center(child: Text('هیچ محصولی وجود ندارد.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshPastries,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pastries.length,
              itemBuilder: (context, index) {
                final pastry = pastries[index];
                return _buildPastryCard(pastry, context);
              },
            ),
          );
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPastryScreen()),
          );
          if (result == true) {
            _refreshPastries();
          }
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildPastryCard(Pastry pastry, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PastryDetailScreen(pastry: pastry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: pastry.imageUrl,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: pastry.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pastry.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pastry.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('موجودی: ${pastry.stock}',
                            style: const TextStyle(color: Colors.orange, fontSize: 13)),
                        Text(
                          '${pastry.price.toStringAsFixed(0)} تومان',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
