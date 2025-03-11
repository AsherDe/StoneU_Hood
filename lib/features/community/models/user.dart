// lib/models/user.dart
class User {
  final String id;
  final String phone;
  final bool verified;
  
  User({
    required this.id,
    required this.phone,
    this.verified = false,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      verified: json['verified'] ?? false,
    );
  }
}