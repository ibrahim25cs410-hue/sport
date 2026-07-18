/// Compile-time payment policy.
///
/// Production builds are cash-only by default. Electronic payment code remains
/// available for a future release only when explicitly compiled with:
/// `--dart-define=ELECTRONIC_PAYMENTS_ENABLED=true`.
abstract final class PaymentPolicy {
  static const electronicPaymentsEnabled = bool.fromEnvironment(
    'ELECTRONIC_PAYMENTS_ENABLED',
    defaultValue: false,
  );

  static const cashOnly = !electronicPaymentsEnabled;

  static void requireElectronicPayments() {
    if (cashOnly) throw const ElectronicPaymentsDisabledException();
  }
}

final class ElectronicPaymentsDisabledException implements Exception {
  const ElectronicPaymentsDisabledException();

  @override
  String toString() => 'Electronic payments are disabled in this build.';
}
