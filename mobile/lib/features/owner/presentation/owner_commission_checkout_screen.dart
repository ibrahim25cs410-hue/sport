import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/owner_payment_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../domain/enums/owner_payment_gateway.dart';
import '../../../models/owner_payment_account.dart';
import '../../../providers/booking_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/price_text.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../payment/presentation/payment_widgets.dart';

/// صفحة دفع عمولة المنصة للمالك — فواتير مستحقة + زين كاش أو بطاقة.
class OwnerCommissionCheckoutScreen extends ConsumerStatefulWidget {
  const OwnerCommissionCheckoutScreen({super.key});

  @override
  ConsumerState<OwnerCommissionCheckoutScreen> createState() => _OwnerCommissionCheckoutScreenState();
}

class _OwnerCommissionCheckoutScreenState extends ConsumerState<OwnerCommissionCheckoutScreen> {
  OwnerPaymentGateway _gateway = OwnerPaymentGateway.zainCash;
  int? _selectedInvoiceId;
  String? _pendingToken;
  bool _paying = false;
  bool _verifying = false;

  Future<void> _pay(OwnerFeeInvoice invoice) async {
    final key = watchSessionKey(ref);
    if (key == null) return;

    setState(() {
      _paying = true;
      _selectedInvoiceId = invoice.id;
      _pendingToken = null;
    });

    try {
      final orchestrator = ref.read(ownerPaymentOrchestratorProvider(key.client));
      final result = await orchestrator.startExternalPayment(invoiceId: invoice.id, gateway: _gateway);
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
      final orchestrator = ref.read(ownerPaymentOrchestratorProvider(key.client));
      final event = await orchestrator.verifyPayment(token);
      if (!mounted) return;

      if (event == null) {
        showAppSnackBar(context, l10n.paymentVerifyFailed);
        return;
      }

      ref.read(ownerPaymentAccountProvider(key).notifier).applyVerified(event);
      ref.invalidate(ownerPaymentAccountProvider(key));
      ref.invalidate(ownerDashboardProvider(key));

      setState(() => _pendingToken = null);
      showAppSnackBar(context, event.message.isNotEmpty ? event.message : l10n.paymentSuccess);
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
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final accountAsync = ref.watch(ownerPaymentAccountProvider(key));
    final account = accountAsync.valueOrNull;
    final loading = accountAsync.isLoading && account == null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ownerCommissionCheckout)),
      body: loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : account == null
              ? EmptyState(icon: Icons.error_outline_rounded, title: l10n.retry, subtitle: l10n.connectionLost)
              : RefreshIndicator(
                  color: c.primary,
                  onRefresh: () => ref.read(ownerPaymentAccountProvider(key).notifier).refreshPreservingData(),
                  child: ListView(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    children: [
                      _OutstandingBanner(account: account),
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
                      Text(l10n.outstandingInvoices, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: DesignTokens.spaceSm),
                      if (account.pendingInvoices.isEmpty)
                        EmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          title: l10n.noOutstandingInvoices,
                          subtitle: l10n.noOutstandingInvoicesHint,
                        )
                      else
                        ...account.pendingInvoices.map((invoice) => _InvoiceCard(
                              invoice: invoice,
                              paying: _paying && _selectedInvoiceId == invoice.id,
                              onPay: () => _pay(invoice),
                            )),
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
                                  Expanded(
                                    child: Text(
                                      l10n.verifyPaymentHint,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DesignTokens.spaceMd),
                              PayNowButton(
                                amount: account.outstandingAmount,
                                loading: _verifying,
                                label: l10n.verifyPayment,
                                onPressed: _verify,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (account.paidInvoices.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.spaceXl),
                        Text(l10n.paidInvoices, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: DesignTokens.spaceSm),
                        ...account.paidInvoices.take(5).map((i) => _PaidInvoiceRow(invoice: i)),
                      ],
                      if (account.recentPayments.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.spaceXl),
                        Text(l10n.paymentHistory, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: DesignTokens.spaceSm),
                        ...account.recentPayments.take(8).map((p) => _PaymentHistoryRow(payment: p)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _OutstandingBanner extends StatelessWidget {
  const _OutstandingBanner({required this.account});
  final OwnerPaymentAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        gradient: context.heroBannerGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.outstandingCommission, style: TextStyle(color: c.onInverseMuted, fontSize: 13)),
          const SizedBox(height: 4),
          PriceText(
            formatMoney(account.outstandingAmount),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.platformCommissionRate,
            style: TextStyle(color: c.onInverseMuted, fontSize: 12),
          ),
          if (account.outstandingHours > 0)
            Text(
              l10n.outstandingHours(account.outstandingHours),
              style: TextStyle(color: c.onInverseMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

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

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.paying, required this.onPay});

  final OwnerFeeInvoice invoice;
  final bool paying;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
      child: GlassSurface(
        borderRadius: DesignTokens.radiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l10n.invoiceHoursBookings(invoice.totalHours, invoice.bookingCount)),
            PriceText(
              formatMoney(invoice.amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            PayNowButton(amount: invoice.amount, loading: paying, onPressed: onPay),
          ],
        ),
      ),
    );
  }
}

class _PaidInvoiceRow extends StatelessWidget {
  const _PaidInvoiceRow({required this.invoice});
  final OwnerFeeInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.receipt_long_rounded, color: c.primary),
      title: Text(invoice.title),
      subtitle: PriceText(formatMoney(invoice.amount), style: Theme.of(context).textTheme.bodySmall),
      trailing: Icon(Icons.check_circle_rounded, color: c.primary, size: 20),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({required this.payment});
  final OwnerPaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gatewayLabel = payment.gateway == 'zaincash' ? l10n.payZainCash : l10n.payCard;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history_rounded),
      title: Row(
        children: [
          Expanded(child: Text('$gatewayLabel —')),
          PriceText(formatMoney(payment.amount), style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
      subtitle: Text(payment.status),
    );
  }
}
