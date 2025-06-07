import 'package:flutter/material.dart';
import 'package:bakery/home_screens/cart_screen.dart';
import 'package:bakery/home_screens/shop_screen.dart';
import 'package:bakery/home_screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widget/login_required_dialog.dart';
import '../screens/authentication/login/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  bool _dialogShown = false;

  final List<Widget> _screens = const [
    CartScreen(),
    ShopScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // If user is not authenticated and tries to access Cart or Profile
    if ((index == 0 || index == 2) && !userProvider.isAuthenticated) {
      if (!_dialogShown) {
        _dialogShown = true;
        final result = await showLoginRequiredDialog(context);
        if (result == 'login') {
          if (mounted) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        }
        _dialogShown = false;
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
