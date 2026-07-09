class Stadium {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String? image;
  final int pricePerHour;
  final int ownerId;
  final String description;
  final double? latitude;
  final double? longitude;

  const Stadium({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.image,
    required this.pricePerHour,
    required this.ownerId,
    this.description = '',
    this.latitude,
    this.longitude,
  });

  factory Stadium.fromJson(Map<String, dynamic> json) => Stadium(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        image: json['image'] as String?,
        pricePerHour: json['pricePerHour'] as int? ?? 0,
        ownerId: json['ownerId'] as int,
        description: json['description'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
