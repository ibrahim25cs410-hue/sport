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

  factory User.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    final rawRole = (json['role'] as String?)?.trim().toLowerCase();
    return User(
      id: _asInt(json['id']) ?? _stableId(email),
      name: json['name'] as String? ?? '',
      email: email,
      phone: json['phone'] as String? ?? '',
      province: json['province'] as String? ?? 'نينوى',
      image: json['image'] as String?,
      role: _normalizeRole(rawRole),
      loyaltyPoints: _asInt(json['loyaltyPoints']) ?? 0,
    );
  }

  static String _normalizeRole(String? role) {
    if (role == 'owner' || role == 'admin' || role == 'user') return role!;
    return 'user';
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static int _stableId(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = 0x1fffffff & (h + c);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= h >> 6;
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= h >> 11;
    h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
    return h == 0 ? 1 : h.abs();
  }

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
