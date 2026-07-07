enum UserRole {
  customer('customer'),
  owner('owner'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? raw) => UserRole.values.firstWhere(
        (r) => r.value == raw,
        orElse: () => UserRole.customer,
      );
}
