/// مصدر واحد لقواعد العمولة والتسعير المالي في التطبيق.
abstract final class FinancialConstants {
  /// نسبة عمولة المنصة (10%).
  static const double platformCommissionRate = 0.10;

  /// سعر افتراضي للملعب عند غياب السعر (د.ع) — ليس عمولة.
  static const int defaultFieldPricePerHourIqd = 2000;

  /// عمولة المنصة = (سعر الساعة × عدد الساعات) × 10%.
  static int calculateCommission({required int pricePerHour, required int hours}) =>
      roundIqd(pricePerHour * hours * platformCommissionRate);

  /// عمولة المنصة من إجمالي الحجز.
  static int calculateCommissionFromTotal(int totalPrice) =>
      roundIqd(totalPrice * platformCommissionRate);

  /// صافي ربح المالك = إجمالي الدخل − عمولة المنصة.
  static int netRevenue({required int grossRevenue, required int commission}) =>
      grossRevenue - commission;

  /// تقريب مالي (بعيداً عن الصفر) لتجنب كسور العملة.
  static int roundIqd(num amount) {
    if (amount >= 0) {
      return (amount + 0.5).floor();
    }
    return (amount - 0.5).ceil();
  }
}
