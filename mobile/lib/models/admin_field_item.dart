class AdminFieldItem {
  const AdminFieldItem({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerId,
    required this.ownerName,
    required this.isActive,
  });

  final int id;
  final String name;
  final String address;
  final int ownerId;
  final String ownerName;
  final bool isActive;

  factory AdminFieldItem.fromJson(Map<String, dynamic> json) => AdminFieldItem(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        ownerId: json['ownerId'] as int? ?? 0,
        ownerName: json['ownerName'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );
}
