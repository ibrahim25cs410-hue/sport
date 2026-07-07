enum PaymentMethod {
  cash('cash'),
  online('online');

  const PaymentMethod(this.apiValue);
  final String apiValue;

  static PaymentMethod fromApi(String? raw) =>
      raw?.toLowerCase() == 'cash' ? PaymentMethod.cash : PaymentMethod.online;
}
