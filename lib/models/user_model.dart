import 'dart:convert';

class UserModel {
  final int id;
  final String email;
  final String name;
  final bool isVerified;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.isVerified,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      isVerified: json['is_verified'],
      isAdmin: json['is_admin']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'is_verified': isVerified,
      'is_admin': isAdmin,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) =>
      UserModel.fromJson(jsonDecode(jsonString));
}
