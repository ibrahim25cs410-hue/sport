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

  factory Field.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final address = json['address'] as String? ?? '';
    final phone = json['phone'] as String? ?? '';
    return Field(
      id: _asInt(json['id']) ?? _stableId('$name|$phone|$address'),
      name: name,
      address: address,
      phone: phone,
      image: json['image'] as String?,
      pricePerHour: _asInt(json['pricePerHour']) ?? 0,
      ownerId: _asInt(json['ownerId']) ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: _asInt(json['reviewCount']) ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// معرّف احتياطي عندما السيرفر السحابي لا يُرجع id (بيانات قديمة).
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
}
