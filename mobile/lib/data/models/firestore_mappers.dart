import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/field_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/enums/field_category.dart';
import '../../domain/enums/user_role.dart';

/// Firestore DTO ↔ domain entity mappers.
abstract final class FirestoreMappers {
  static UserEntity userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserEntity(
      id: doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      province: d['province'] as String? ?? 'نينوى',
      imageUrl: d['imageUrl'] as String?,
      role: UserRole.fromString(d['role'] as String?),
      fcmToken: d['fcmToken'] as String?,
      referralCode: d['referralCode'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> userToMap(UserEntity u) => {
        'name': u.name,
        'email': u.email,
        'phone': u.phone,
        'province': u.province,
        'imageUrl': u.imageUrl,
        'role': u.role.value,
        'fcmToken': u.fcmToken,
        'referralCode': u.referralCode,
        'createdAt': u.createdAt != null ? Timestamp.fromDate(u.createdAt!) : FieldValue.serverTimestamp(),
      };

  static FieldEntity fieldFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FieldEntity(
      id: doc.id,
      name: d['name'] as String? ?? '',
      address: d['address'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      pricePerHour: (d['pricePerHour'] as num?)?.toInt() ?? 0,
      ownerId: d['ownerId'] as String? ?? '',
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? []),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      category: FieldCategory.fromString(d['category'] as String?),
      isIndoor: d['isIndoor'] as bool? ?? false,
      isAvailable: d['isAvailable'] as bool? ?? true,
      averageRating: (d['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      amenities: List<String>.from(d['amenities'] as List? ?? []),
      description: d['description'] as String?,
    );
  }

  static BookingEntity bookingFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BookingEntity(
      id: doc.id,
      fieldId: d['fieldId'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      fieldName: d['fieldName'] as String? ?? '',
      fieldAddress: d['fieldAddress'] as String? ?? '',
      startTime: (d['startTime'] as Timestamp).toDate(),
      endTime: (d['endTime'] as Timestamp).toDate(),
      hours: (d['hours'] as num?)?.toInt() ?? 1,
      totalPrice: (d['totalPrice'] as num?)?.toInt() ?? 0,
      status: BookingStatus.fromString(d['status'] as String?),
      referenceCode: d['referenceCode'] as String?,
      fieldImage: d['fieldImage'] as String?,
      qrCode: d['qrCode'] as String?,
      couponCode: d['couponCode'] as String?,
    );
  }
}
