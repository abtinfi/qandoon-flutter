import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widget/login_required_dialog.dart';
import '../screens/authentication/login/login_screen.dart';
import '../screens/authentication/forgot_password/forgot_password_otp_screen.dart';
import '../models/user_model.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  bool _dialogShown = false;

  Future<void> _updateUsername(String newName) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.put(
        Uri.parse('https://api.abtinfi.ir/users/username'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': newName}),
      );

      if (response.statusCode == 200) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final updatedUser = userProvider.user;
        if (updatedUser != null) {
          final newUser = UserModel(
            id: updatedUser.id,
            email: updatedUser.email,
            name: newName,
            isVerified: updatedUser.isVerified,
            isAdmin: updatedUser.isAdmin,
          );
          userProvider.setUser(newUser);
          await _storage.write(
            key: 'user',
            value: jsonEncode(newUser.toJson()),
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
      } else {
        throw Exception('Failed to update username');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: 4{e.toString()}')),
      );
    }
  }

  void _showChangeNameDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Change Username'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'New Name',
                hintText: 'A new name must be entered',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _updateUsername(value);
                  Navigator.pop(context);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    _updateUsername(nameController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  Widget _buildUserInfo(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('👤 Name: ${user.name}', style: const TextStyle(fontSize: 16)),
            Text('📧 Email: ${user.email}'),
            Text('🔑 Verified: ${user.isVerified ? 'Yes' : 'No'}'),
            Text('🧩 Role: ${user.isAdmin ? 'Admin' : 'Customer'}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showChangeNameDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Change Username'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordEnterEmailScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.lock_reset),
              label: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPanel() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Panel',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Welcome to the admin panel. You can manage orders below.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Manage Orders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
        );
      },
      icon: const Icon(Icons.list),
      label: const Text('View Orders'),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        await Provider.of<UserProvider>(context, listen: false).logout();
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (!userProvider.isAuthenticated || user == null) {
      if (!_dialogShown) {
        _dialogShown = true;
        Future.microtask(() async {
          final result = await showLoginRequiredDialog(context);
          if (result == 'login' && context.mounted) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
          _dialogShown = false;
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (user.isAdmin) _buildAdminPanel(),
            _buildUserInfo(user),
            if (!(user.isAdmin)) _buildOrderButton(),
            const SizedBox(height: 16),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }
}
