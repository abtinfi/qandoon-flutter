// home_screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/authentication/login/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final user = userProvider.user;

    if (userProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('پروفایل کاربری')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${user!.id}'),
              Text('نام: ${user.name}'),
              Text('ایمیل: ${user.email}'),
              Text('تایید شده: ${user.isVerified ? 'بله' : 'خیر'}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  await userProvider.logout();

                  if (!context.mounted) return;

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('خروج از حساب'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('پروفایل')),
        body: const Center(child: Text('لطفا برای مشاهده پروفایل لاگین کنید.')),
      );
    }
  }
}
