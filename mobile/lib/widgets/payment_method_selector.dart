import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../widgets/premium/glass_surface.dart';

/// Lets the user choose cash (pay at venue) or online payment before booking.
Future<PaymentMethod?> showPaymentMethodSelector(BuildContext context) {
  final l10n = context.l10n;
  final c = context.colors;

  return showModalBottomSheet<PaymentMethod>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spaceXl,
        0,
        DesignTokens.spaceXl,
        DesignTokens.spaceXl + MediaQuery.of(ctx).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.paymentMethod,
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.paymentMethodHint,
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _OptionTile(
            icon: Icons.payments_rounded,
            title: l10n.payOnline,
            subtitle: l10n.payOnlineHint,
            onTap: () => Navigator.pop(ctx, PaymentMethod.online),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.money_rounded,
            title: l10n.payCash,
            subtitle: l10n.payCashHint,
            accent: DesignTokens.primaryTeal,
            onTap: () => Navigator.pop(ctx, PaymentMethod.cash),
          ),
        ],
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = accent ?? c.primary;
    return GlassSurface(
      borderRadius: DesignTokens.radiusLg,
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
      ),
    );
  }
}
