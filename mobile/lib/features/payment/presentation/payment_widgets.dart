import 'package:flutter/material.dart';

import '../../../domain/enums/owner_payment_gateway.dart';
import '../../../domain/enums/payment_method.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/premium/glass_surface.dart';

class PaymentGatewaySelector extends StatelessWidget {
  const PaymentGatewaySelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.saving = false,
  });

  final OwnerPaymentGateway selected;
  final ValueChanged<OwnerPaymentGateway> onSelected;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final gateways = <(OwnerPaymentGateway, String, String, IconData)>[
      (OwnerPaymentGateway.zainCash, l10n.payZainCash, l10n.payZainCashHint, Icons.account_balance_wallet_rounded),
      (OwnerPaymentGateway.card, l10n.payCard, l10n.payCardHint, Icons.credit_card_rounded),
    ];

    return ListView(
      children: gateways.map((entry) {
        final (gateway, label, subtitle, icon) = entry;
        final active = gateway == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassSurface(
            borderRadius: DesignTokens.radiusLg,
            padding: EdgeInsets.zero,
            onTap: saving ? null : () => onSelected(gateway),
            child: ListTile(
              leading: Icon(icon, color: active ? c.primary : c.onSurfaceVariant),
              title: Text(label, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              trailing: saving && active
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                    )
                  : active
                      ? Icon(Icons.check_circle_rounded, color: c.primary)
                      : Icon(Icons.circle_outlined, color: c.onSurfaceVariant),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final methods = <(PaymentMethod, String, IconData)>[
      (PaymentMethod.visa, l10n.payVisa, Icons.credit_card_rounded),
      (PaymentMethod.mastercard, l10n.payMastercard, Icons.credit_card_rounded),
      (PaymentMethod.applePay, l10n.payApplePay, Icons.apple_rounded),
      (PaymentMethod.googlePay, l10n.payGooglePay, Icons.account_balance_wallet_outlined),
      (PaymentMethod.cash, l10n.payCash, Icons.payments_outlined),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: methods.map((m) {
        final (method, label, icon) = m;
        final active = method == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassSurface(
            borderRadius: DesignTokens.radiusLg,
            padding: EdgeInsets.zero,
            onTap: () => onSelected(method),
            child: ListTile(
              leading: Icon(icon, color: active ? c.primary : c.onSurfaceVariant),
              title: Text(label),
              trailing: active
                  ? Icon(Icons.check_circle_rounded, color: c.primary)
                  : Icon(Icons.circle_outlined, color: c.onSurfaceVariant),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    super.key,
    required this.fieldName,
    required this.date,
    required this.hours,
    required this.total,
    this.discount = 0,
  });

  final String fieldName;
  final String date;
  final int hours;
  final int total;
  final int discount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;

    return GlassSurface(
      borderRadius: DesignTokens.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentSummary, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _row(c, l10n.fieldLabel, fieldName),
          _row(c, l10n.dateLabel, date),
          _row(c, l10n.hoursLabel, '$hours'),
          if (discount > 0) _row(c, l10n.discountLabel, '-$discount', color: c.primary),
          const Divider(),
          _row(c, l10n.totalLabel, '$total', bold: true),
        ],
      ),
    );
  }

  Widget _row(RiyadaColors c, String k, String v, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: TextStyle(color: c.onSurfaceVariant)),
            Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? c.onSurface)),
          ],
        ),
      );
}

class PayNowButton extends StatelessWidget {
  const PayNowButton({
    super.key,
    required this.amount,
    required this.onPressed,
    this.loading = false,
    this.label,
  });

  final int amount;
  final VoidCallback? onPressed;
  final bool loading;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
        ),
        child: loading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label ?? '${l10n.payNow} — $amount',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  maxLines: 1,
                ),
              ),
      ),
    );
  }
}
