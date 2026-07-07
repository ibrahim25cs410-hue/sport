enum PasswordStrength { weak, fair, good, strong }

PasswordStrength evaluatePasswordStrength(String password) {
  if (password.length < 6) return PasswordStrength.weak;
  var score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
  if (score <= 1) return PasswordStrength.weak;
  if (score == 2) return PasswordStrength.fair;
  if (score == 3) return PasswordStrength.good;
  return PasswordStrength.strong;
}

String passwordStrengthLabelAr(PasswordStrength s) => switch (s) {
      PasswordStrength.weak => 'ضعيفة',
      PasswordStrength.fair => 'مقبولة',
      PasswordStrength.good => 'جيدة',
      PasswordStrength.strong => 'قوية',
    };
