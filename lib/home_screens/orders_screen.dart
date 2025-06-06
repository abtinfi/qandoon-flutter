import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = false;
  List<OrderModel> _orders = [];
  String _selectedStatus = 'all';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await OrderService.fetchOrders();
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load orders')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<OrderModel> _filteredAndSortedOrders() {
    final filtered = _selectedStatus == 'all'
        ? _orders
        : _orders.where((o) => o.status.toLowerCase() == _selectedStatus).toList();

    filtered.sort((a, b) =>
    _sortDescending ? b.id.compareTo(a.id) : a.id.compareTo(b.id));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final displayedOrders = _filteredAndSortedOrders();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayedOrders.isEmpty
          ? const Center(child: Text('No orders found.'))
          : RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayedOrders.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildFilters();
            final order = displayedOrders[index - 1];
            return _buildOrderCard(order);
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: _sortDescending ? 'Newest' : 'Oldest',
            icon: _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
            onTap: () => setState(() => _sortDescending = !_sortDescending),
          ),
          _buildFilterChip(
            label: _getStatusLabel(_selectedStatus),
            icon: Icons.filter_alt_outlined,
            onTap: _showStatusFilterModal,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showStatusFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusTile('all', 'All Orders'),
          _buildStatusTile('pending', 'Pending'),
          _buildStatusTile('accepted', 'Accepted'),
          _buildStatusTile('rejected', 'Rejected'),
        ],
      ),
    );
  }

  Widget _buildStatusTile(String statusValue, String title) {
    return ListTile(
      title: Text(title),
      onTap: () {
        setState(() => _selectedStatus = statusValue);
        Navigator.pop(context);
      },
      trailing: _selectedStatus == statusValue
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return 'All Orders';
    }
  }

  Widget _buildOrderCard(OrderModel order) {
    return Hero(
      tag: 'order-${order.id}',
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(order),
                const SizedBox(height: 12),
                Text('📍 Address: ${order.address}'),
                Text('📞 Phone: ${order.phoneNumber}'),
                if (order.adminMessage?.isNotEmpty == true)
                  Text('📝 Admin Message: ${order.adminMessage}'),
                const SizedBox(height: 8),
                Text(
                  'Date: ${_formatDate(order.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Order #${order.id}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusLabel(order.status),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${_twoDigits(date.month)}/${_twoDigits(date.day)} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
