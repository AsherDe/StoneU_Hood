class User {
  final String id;
  final String phone;
  final String name;
  final String? department;
  final String? grade;
  final bool verified;
  
  User({
    required this.id,
    required this.phone,
    required this.name,
    this.department,
    this.grade,
    this.verified = false,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      department: json['department'],
      grade: json['grade'],
      verified: json['verified'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'department': department,
      'grade': grade,
      'verified': verified,
    };
  }
}