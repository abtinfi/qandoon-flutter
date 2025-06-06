class OrderItem {
  final int pastryId;
  final int quantity;

  OrderItem({required this.pastryId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'pastry_id': pastryId,
    'quantity': quantity,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      pastryId: json['pastry_id'],
      quantity: json['quantity'],
    );
  }
}

class OrderCreateModel {
  final String address;
  final String phoneNumber;
  final List<OrderItem> items;

  OrderCreateModel({
    required this.address,
    required this.phoneNumber,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'phone_number': phoneNumber,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class OrderModel {
  final int id;
  final String address;
  final String phoneNumber;
  final String status;
  final String? adminMessage;
  final DateTime createdAt;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.address,
    required this.phoneNumber,
    required this.status,
    this.adminMessage,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      address: json['address'],
      phoneNumber: json['phone_number'],
      status: json['status'],
      adminMessage: json['admin_message'],
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }
}
