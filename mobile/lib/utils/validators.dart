/// تحقق من صحة البريد الإلكتروني.
final RegExp emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

/// هاتف عراقي: يبدأ بـ 07 وطوله 11 رقماً.
final RegExp iraqiPhoneRegex = RegExp(r'^07\d{9}$');

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'أدخل البريد الإلكتروني';
  if (!emailRegex.hasMatch(value.trim())) {
    return 'أدخل بريداً صحيحاً (مثال: name@email.com)';
  }
  return null;
}

String? validateIraqiPhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'أدخل رقم الهاتف';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (!iraqiPhoneRegex.hasMatch(digits)) {
    return 'رقم غير صحيح (مثال: 07701234567)';
  }
  return null;
}

String? validatePassword(String? value, {int minLength = 6}) {
  if (value == null || value.isEmpty) return 'أدخل كلمة المرور';
  if (value.length < minLength) return '$minLength أحرف على الأقل';
  return null;
}

String? validateRequired(String? value, {String label = 'هذا الحقل'}) {
  if (value == null || value.trim().isEmpty) return '$label مطلوب';
  return null;
}
