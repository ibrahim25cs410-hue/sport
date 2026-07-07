enum PaymentMethod {
  visa('visa'),
  mastercard('mastercard'),
  applePay('apple_pay'),
  googlePay('google_pay'),
  cash('cash');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String? raw) => PaymentMethod.values.firstWhere(
        (m) => m.value == raw,
        orElse: () => PaymentMethod.cash,
      );
}
