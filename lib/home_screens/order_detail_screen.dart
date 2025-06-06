import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/pastry_model.dart';
import '../providers/user_provider.dart';
import '../services/order_service.dart';
import 'detail_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;
  List<Pastry> _pastries = [];
  final _adminMessageController = TextEditingController();
  String _selectedStatus = 'pending';
  bool _showAllPastries = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
    _adminMessageController.text = widget.order.adminMessage ?? '';
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _adminMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    try {
      final details = await OrderService.fetchOrderDetails(widget.order.id);
      setState(() => _pastries = details['pastries']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load order details')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await OrderService.updateOrderStatus(
        widget.order.id,
        status: _selectedStatus,
        adminMessage: _adminMessageController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAdminControls() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Order Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStatus = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _adminMessageController,
              decoration: const InputDecoration(
                labelText: 'Message to Customer',
                border: OutlineInputBorder(),
                hintText: 'Type your message here...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      setState(() => _selectedStatus = 'accepted');
                      _updateOrderStatus();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      setState(() => _selectedStatus = 'rejected');
                      _updateOrderStatus();
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final order = widget.order;

    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('📍 Address: ${order.address}'),
              Text('📞 Phone: ${order.phoneNumber}'),
              Text('🗓 Status: ${_getStatusText(order.status)}'),
              if (order.adminMessage?.isNotEmpty == true)
                Text('📝 Admin Message: ${order.adminMessage}'),
              Text(
                '📅 Date: ${_formatDate(order.createdAt)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPastryList() {
    final items = widget.order.items;
    final int itemCountToShow = _showAllPastries ? items.length : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pastries List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        for (var i = 0; i < itemCountToShow && i < _pastries.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _pastries[i].imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40),
                ),
              ),
              title: Text(_pastries[i].name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price: ${_pastries[i].price.toStringAsFixed(0)} Toman'),
                  Text('Quantity: ${items[i].quantity}'),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PastryDetailScreen(pastry: _pastries[i]),
                  ),
                );
              },
            ),
          ),

        if (_pastries.length > 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _showAllPastries = !_showAllPastries);
              },
              icon: Icon(_showAllPastries ? Icons.expand_less : Icons.expand_more),
              label: Text(_showAllPastries ? 'Show Less' : 'Show More'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserProvider>(context).user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.order.id}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfoCard(),
            const SizedBox(height: 24),
            _buildPastryList(),
            if (isAdmin) ...[
              const SizedBox(height: 18),
              _buildAdminControls(),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
  }
}
