class Pastry {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final int stock;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Pastry({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.createdAt,
    this.updatedAt,
  });

  factory Pastry.fromJson(Map<String, dynamic> json) {
    return Pastry(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: 'https://api.abtinfi.ir/${json['image_url'].toString().replaceFirst(RegExp(r'^/'), '')}',
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}
