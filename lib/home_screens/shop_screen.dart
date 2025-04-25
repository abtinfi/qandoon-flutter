import 'package:flutter/material.dart';
import '../models/pastry_model.dart';
import '../services/pastry_service.dart';
import 'detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late Future<List<Pastry>> _pastriesFuture;

  @override
  void initState() {
    super.initState();
    _pastriesFuture = PastryService.fetchPastries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Pastry>>(
        future: _pastriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطا: ${snapshot.error}'));
          }

          final pastries = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pastries.length,
            itemBuilder: (context, index) {
              final pastry = pastries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PastryDetailScreen(pastry: pastry),
                      ),
                    );
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Hero(
                      tag: pastry.imageUrl,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.network(
                            pastry.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                    ),
                    title: Text(pastry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(pastry.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      '${pastry.price.toStringAsFixed(0)} تومان',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}