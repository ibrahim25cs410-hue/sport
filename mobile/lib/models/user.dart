class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String province;
  final String? image;
  final String role;
  final int loyaltyPoints;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.province,
    this.image,
    required this.role,
    this.loyaltyPoints = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        province: json['province'] as String? ?? 'نينوى',
        image: json['image'] as String?,
        role: json['role'] as String? ?? 'user',
        loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      );

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? province,
    String? image,
    String? role,
    int? loyaltyPoints,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        province: province ?? this.province,
        image: image ?? this.image,
        role: role ?? this.role,
        loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      );

  bool get isOwner => role == 'owner';

  bool get isAdmin => role == 'admin';

  String get roleLabel {
    if (isAdmin) return 'مدير';
    if (isOwner) return 'صاحب ملعب';
    return 'مستخدم';
  }
}

