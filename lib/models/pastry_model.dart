class Pastry {
  final String name;
  final String description;
  final String imageUrl;
  final double price;

  Pastry({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
  });

  factory Pastry.fromJson(Map<String, dynamic> json) {
    return Pastry(
      name: json['name'],
      description: json['description'],
      imageUrl: json['image'],
      price: double.parse(json['price'].toString()),
    );
  }
}