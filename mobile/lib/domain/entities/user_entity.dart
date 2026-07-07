import '../enums/user_role.dart';

class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.province,
    this.imageUrl,
    this.role = UserRole.customer,
    this.fcmToken,
    this.referralCode,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String province;
  final String? imageUrl;
  final UserRole role;
  final String? fcmToken;
  final String? referralCode;
  final DateTime? createdAt;

  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.admin;
}
