class Field {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String? image;
  final int pricePerHour;
  final int ownerId;
  final double averageRating;
  final int reviewCount;
  final double? latitude;
  final double? longitude;

  const Field({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.image,
    required this.pricePerHour,
    required this.ownerId,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory Field.fromJson(Map<String, dynamic> json) => Field(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        image: json['image'] as String?,
        pricePerHour: json['pricePerHour'] as int? ?? 0,
        ownerId: json['ownerId'] as int? ?? 0,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
