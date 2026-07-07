/// Firestore collection & document paths — Riyada schema.
abstract final class FirestorePaths {
  static const users = 'users';
  static const owners = 'owners';
  static const fields = 'fields';
  static const bookings = 'bookings';
  static const payments = 'payments';
  static const reviews = 'reviews';
  static const favorites = 'favorites';
  static const notifications = 'notifications';
  static const offers = 'offers';
  static const coupons = 'coupons';
  static const referrals = 'referrals';
  static const chatThreads = 'chat_threads';

  static String user(String uid) => '$users/$uid';
  static String owner(String uid) => '$owners/$uid';
  static String field(String id) => '$fields/$id';
  static String booking(String id) => '$bookings/$id';
  static String userFavorites(String uid) => '$users/$uid/$favorites';
  static String userNotifications(String uid) => '$users/$uid/$notifications';
}
