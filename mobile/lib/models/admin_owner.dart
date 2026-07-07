class AdminOwner {
  const AdminOwner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.fieldCount,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final int fieldCount;

  factory AdminOwner.fromJson(Map<String, dynamic> json) => AdminOwner(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        fieldCount: json['fieldCount'] as int? ?? 0,
      );
}
