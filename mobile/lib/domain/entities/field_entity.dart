import '../enums/field_category.dart';

class FieldEntity {
  const FieldEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.pricePerHour,
    required this.ownerId,
    this.imageUrls = const [],
    this.latitude,
    this.longitude,
    this.category = FieldCategory.fiveVfive,
    this.isIndoor = false,
    this.isAvailable = true,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.distanceKm,
    this.amenities = const [],
    this.description,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final int pricePerHour;
  final String ownerId;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;
  final FieldCategory category;
  final bool isIndoor;
  final bool isAvailable;
  final double averageRating;
  final int reviewCount;
  final double? distanceKm;
  final List<String> amenities;
  final String? description;

  String? get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : null;
}
