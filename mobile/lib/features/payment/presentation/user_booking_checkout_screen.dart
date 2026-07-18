import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/payment_policy.dart';
import '../../../core/providers/user_booking_payment_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../domain/enums/owner_payment_gateway.dart';
import '../../../models/booking_checkout_args.dart';
import '../../../providers/booking_provider.dart';
import '../../../services/payment_preferences_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/price_text.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../payment/presentation/payment_widgets.dart';

class _GatewayTile extends StatelessWidget {
  const _GatewayTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GlassSurface(
      borderRadius: DesignTokens.radiusLg,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: selected ? c.primary : c.onSurfaceVariant),
        title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: c.primary)
            : Icon(Icons.circle_outlined, color: c.onSurfaceVariant),
      ),
    );
  }
}

/// دفع حجز المستخدم — زين كاش أو بطاقة قبل موافقة المالك.
class UserBookingCheckoutScreen extends ConsumerStatefulWidget {
  const UserBookingCheckoutScreen({super.key, required this.args});

  final BookingCheckoutArgs args;

  @override
  ConsumerState<UserBookingCheckoutScreen> createState() => _UserBookingCheckoutScreenState();
}

class _UserBookingCheckoutScreenState extends ConsumerState<UserBookingCheckoutScreen> {
  OwnerPaymentGateway _gateway = OwnerPaymentGateway.zainCash;
  String? _pendingToken;
  bool _paying = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    PaymentPreferencesService.loadGateway().then((gateway) {
      if (mounted) setState(() => _gateway = gateway);
    });
  }

  Future<void> _pay() async {
    final key = watchSessionKey(ref);
    if (key == null) return;

    setState(() {
      _paying = true;
      _pendingToken = null;
    });

    try {
      final orchestrator = ref.read(userBookingPaymentOrchestratorProvider(key.client));
      final result = await orchestrator.startExternalPayment(
        bookingId: widget.args.bookingId,
        gateway: _gateway,
      );
      if (!mounted) return;

      if (!result.launch.launched) {
        showAppSnackBar(context, context.l10n.paymentLaunchFailed);
        return;
      }

      setState(() => _pendingToken = result.initiation.transactionToken);
      showAppSnackBar(context, context.l10n.completePaymentThenVerify);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _verify() async {
    final token = _pendingToken;
    if (token == null) return;

    final key = watchSessionKey(ref);
    if (key == null) return;

    setState(() => _verifying = true);
    final l10n = context.l10n;
    try {
      final orchestrator = ref.read(userBookingPaymentOrchestratorProvider(key.client));
      final result = await orchestrator.verifyPayment(token);
      if (!mounted) return;

      if (!result.success) {
        showAppSnackBar(context, l10n.paymentVerifyFailed);
        return;
      }

      ref.invalidate(userBookingsProvider(key));
      showAppSnackBar(context, result.message.isNotEmpty ? result.message : l10n.paymentSuccess);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final args = widget.args;
    if (PaymentPolicy.cashOnly) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.payNow)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.money_rounded, size: 52),
                const SizedBox(height: DesignTokens.spaceMd),
                Text(
                  l10n.cashOnlyTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Text(
                  l10n.electronicPaymentsComingSoon,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payNow)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            decoration: BoxDecoration(
              gradient: context.heroBannerGradient,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(args.fieldName, style: TextStyle(color: c.onInverse, fontWeight: FontWeight.w700)),
                if (args.referenceCode != null) ...[
                  const SizedBox(height: 4),
                  Text(args.referenceCode!, style: TextStyle(color: c.onInverseMuted, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                Text(l10n.totalLabel, style: TextStyle(color: c.onInverseMuted, fontSize: 13)),
                PriceText(
                  formatMoney(args.totalPrice),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Text(l10n.selectPaymentMethod, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DesignTokens.spaceSm),
          _GatewayTile(
            selected: _gateway == OwnerPaymentGateway.zainCash,
            icon: Icons.account_balance_wallet_rounded,
            label: l10n.payZainCash,
            subtitle: l10n.payZainCashHint,
            onTap: () => setState(() => _gateway = OwnerPaymentGateway.zainCash),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          _GatewayTile(
            selected: _gateway == OwnerPaymentGateway.card,
            icon: Icons.credit_card_rounded,
            label: l10n.payCard,
            subtitle: l10n.payCardHint,
            onTap: () => setState(() => _gateway = OwnerPaymentGateway.card),
          ),
          const SizedBox(height: DesignTokens.spaceXl),
          PayNowButton(amount: args.totalPrice, loading: _paying, onPressed: _pay),
          if (_pendingToken != null) ...[
            const SizedBox(height: DesignTokens.spaceLg),
            GlassSurface(
              borderRadius: DesignTokens.radiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security_rounded, color: c.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.verifyPaymentHint, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  PayNowButton(
                    amount: args.totalPrice,
                    loading: _verifying,
                    label: l10n.verifyPayment,
                    onPressed: _verify,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
