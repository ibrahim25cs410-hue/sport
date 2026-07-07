/// بوابات دفع عمولة المنصة للمالك — لا تُخزَّن بيانات البطاقة في التطبيق.
enum OwnerPaymentGateway {
  zainCash('zaincash'),
  card('card');

  const OwnerPaymentGateway(this.apiValue);
  final String apiValue;

  static OwnerPaymentGateway fromApiValue(String raw) =>
      OwnerPaymentGateway.values.firstWhere(
        (g) => g.apiValue == raw,
        orElse: () => OwnerPaymentGateway.card,
      );
}
