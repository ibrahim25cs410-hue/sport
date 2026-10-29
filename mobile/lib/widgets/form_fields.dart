import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../utils/password_strength.dart';

/// تنسيق تلقائي: 07xx xxx xxxx
class IraqiPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      return oldValue;
    }

    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 4 || i == 7) buf.write(' ');
      buf.write(digits[i]);
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneFormField extends StatelessWidget {
  const PhoneFormField({
    super.key,
    required this.controller,
    this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label ?? l10n.phone,
        hintText: '07xx xxx xxxx',
        prefixIcon: const Icon(Icons.phone_outlined),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [IraqiPhoneInputFormatter()],
      validator: validator,
    );
  }
}

class PasswordFormField extends StatefulWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    this.label,
    this.validator,
    this.hint,
    this.showStrength = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final bool showStrength;

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.showStrength) widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    if (widget.showStrength) widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Color _strengthColor(BuildContext context, PasswordStrength s) {
    final c = context.colors;
    return switch (s) {
      PasswordStrength.weak => c.error,
      PasswordStrength.fair => c.warningSurface,
      PasswordStrength.good => c.primaryLight,
      PasswordStrength.strong => c.success,
    };
  }

  String _strengthLabel(BuildContext context, PasswordStrength s) {
    final l10n = context.l10n;
    return switch (s) {
      PasswordStrength.weak => l10n.strengthWeak,
      PasswordStrength.fair => l10n.strengthFair,
      PasswordStrength.good => l10n.strengthGood,
      PasswordStrength.strong => l10n.strengthStrong,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final strength = widget.showStrength ? evaluatePasswordStrength(widget.controller.text) : null;
    final bars = strength != null ? strength.index + 1 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: !_visible,
          decoration: InputDecoration(
            labelText: widget.label ?? l10n.password,
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _visible = !_visible),
              tooltip: _visible ? l10n.hidePassword : l10n.showPassword,
            ),
          ),
          validator: widget.validator,
        ),
        if (strength != null && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsetsDirectional.only(end: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < bars ? _strengthColor(context, strength) : c.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.passwordStrength(_strengthLabel(context, strength)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _strengthColor(context, strength)),
          ),
        ],
      ],
    );
  }
}

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.colors.onPrimary;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(color: onPrimary, strokeWidth: 2.5),
            )
          : icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(label),
    );
  }
}

class EmailFormField extends StatelessWidget {
  const EmailFormField({
    super.key,
    required this.controller,
    this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label ?? l10n.email, prefixIcon: const Icon(Icons.email_outlined)),
      keyboardType: TextInputType.emailAddress,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      validator: validator,
    );
  }
}
