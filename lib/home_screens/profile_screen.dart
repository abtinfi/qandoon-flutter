import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/authentication/login/login_screen.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  List<OrderModel> _orders = [];

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await OrderService.fetchOrders();
      setState(() => _orders = orders);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در دریافت سفارش‌ها')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileInfo(user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 نام: ${user.name}', style: const TextStyle(fontSize: 18)),
            Text('📧 ایمیل: ${user.email}'),
            Text('🔑 تایید شده: ${user.isVerified ? 'بله' : 'خیر'}'),
            Text('🧩 نقش: ${user.isAdmin ? 'مدیر' : 'مشتری'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('هیچ سفارشی یافت نشد.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🧾 لیست سفارشات:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._orders.map((order) => Hero(
          tag: 'order-${order.id}',
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text('سفارش #${order.id}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 آدرس: ${order.address}'),
                  Text('📞 تماس: ${order.phoneNumber}'),
                  Text('🗓 وضعیت: ${order.status}'),
                  Text('📝 پیام مدیر: ${order.adminMessage}'),
                ],
              ),
              isThreeLine: true,
            ),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (!userProvider.isAuthenticated || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('پروفایل')),
        body: const Center(child: Text('لطفا برای مشاهده پروفایل لاگین کنید.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل کاربری')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildProfileInfo(user),
            const SizedBox(height: 24),
            if (!user.isAdmin)
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.list),
                label: const Text('مشاهده لیست سفارشات'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 16),
            if (!user.isAdmin && (_orders.isNotEmpty || _isLoading))
              _buildOrderList(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await userProvider.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('خروج از حساب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
