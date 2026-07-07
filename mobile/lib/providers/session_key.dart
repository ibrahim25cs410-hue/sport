import '../services/api_client.dart';

/// مفتاح جلسة المستخدم — يُستخدم مع Riverpod family providers.
class UserSessionKey {
  const UserSessionKey({required this.client, required this.userId});

  final ApiClient client;
  final int userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSessionKey && userId == other.userId && client == other.client;

  @override
  int get hashCode => Object.hash(client, userId);
}
