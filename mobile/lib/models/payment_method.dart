enum PaymentMethod {
  cash('cash'),
  online('online');

  const PaymentMethod(this.apiValue);
  final String apiValue;

  static PaymentMethod fromApi(String? raw) =>
      raw?.toLowerCase() == 'online'
          ? PaymentMethod.online
          : PaymentMethod.cash;
}
