// lib/features/community/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String department;
  final String grade;
  final bool verified;
  final String verificationStatus;
  final String verificationMethod;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.department,
    required this.grade,
    this.verified = false,
    this.verificationStatus = 'not_submitted',
    this.verificationMethod = 'none',
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      department: json['department'] ?? '',
      grade: json['grade'] ?? '',
      verified: json['verified'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'not_submitted',
      verificationMethod: json['verificationMethod'] ?? 'none',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'department': department,
      'grade': grade,
      'verified': verified,
      'verificationStatus': verificationStatus,
      'verificationMethod': verificationMethod,
    };
  }
}