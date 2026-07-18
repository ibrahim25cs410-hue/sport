import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/payment_policy.dart';
import '../../../core/providers/wallet_providers.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../models/wallet.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/error_messages.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/skeleton_loaders.dart';
import '../../../widgets/price_text.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../shell/shell_layout.dart';

/// Read-only owner wallet with filterable, auditable transaction history.
class OwnerWalletTab extends ConsumerStatefulWidget {
  const OwnerWalletTab({super.key});

  @override
  ConsumerState<OwnerWalletTab> createState() => _OwnerWalletTabState();
}

class _OwnerWalletTabState extends ConsumerState<OwnerWalletTab> {
  WalletTxFilter _filter = WalletTxFilter.all;

  List<WalletTransaction> _filtered(List<WalletTransaction> txs) => switch (_filter) {
        WalletTxFilter.credits => txs.where((t) => t.isCredit).toList(),
        WalletTxFilter.debits => txs.where((t) => !t.isCredit).toList(),
        WalletTxFilter.all => txs,
      };

  IconData _iconFor(WalletTransaction tx) {
    if (tx.isCommissionDebit) return Icons.receipt_long_rounded;
    if (tx.isAdminCredit) return Icons.admin_panel_settings_rounded;
    if (tx.isSystemAdjustment) return Icons.tune_rounded;
    return tx.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
  }

  void _showDetails(BuildContext context, WalletTransaction tx) {
    final l10n = context.l10n;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.spaceLg,
          0,
          DesignTokens.spaceLg,
          DesignTokens.spaceLg + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.transactionDetails,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _DetailRow(label: l10n.transactionType, value: tx.typeLabel),
            _DetailRow(
              label: l10n.transactionAmount,
              value: '${tx.isCredit ? '+' : ''}${formatMoney(tx.amount.abs())}',
              valueColor: AppColors.priceGreen,
            ),
            _DetailRow(
              label: l10n.transactionDate,
              value: DateFormat.yMMMd().add_jm().format(tx.createdAt.toLocal()),
            ),
            _DetailRow(label: l10n.transactionReason, value: tx.displayReason),
            if (tx.adminNote != null && tx.adminNote!.isNotEmpty && tx.adminNote != tx.displayReason)
              _DetailRow(label: l10n.adminTopUpNote, value: tx.adminNote!),
            if (tx.bookingId != null)
              _DetailRow(label: l10n.transactionBookingId, value: '#${tx.bookingId}'),
            if (tx.bookingReference != null && tx.bookingReference!.isNotEmpty)
              _DetailRow(label: l10n.transactionBookingRef, value: tx.bookingReference!),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final walletAsync = ref.watch(ownerWalletProvider(key));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.walletTab),
        actions: PaymentPolicy.electronicPaymentsEnabled
            ? [
                IconButton(
                  icon: const Icon(Icons.receipt_long_rounded),
                  tooltip: l10n.accountsTab,
                  onPressed: () => context.goOwnerCommissionCheckout(),
                ),
              ]
            : null,
      ),
      body: walletAsync.when(
        loading: () => const OwnerDashboardSkeleton(),
        error: (e, _) => RefreshableEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.retry,
          subtitle: friendlyErrorMessage(e),
          onRefresh: () => ref.invalidate(ownerWalletProvider(key)),
        ),
        data: (WalletDetail wallet) {
          final txs = _filtered(wallet.transactions);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerWalletProvider(key)),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spaceLg,
                DesignTokens.spaceLg,
                DesignTokens.spaceLg,
                ShellLayout.bottomInset(context),
              ),
              children: [
                if (wallet.isBlocked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassSurface(
                      borderRadius: DesignTokens.radiusLg,
                      child: ListTile(
                        leading: Icon(Icons.warning_amber_rounded, color: c.warning),
                        title: Text(
                          l10n.walletBlocked,
                          style: TextStyle(color: c.warning, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(l10n.walletBlockedHint),
                      ),
                    ),
                  ),
                GlassSurface(
                  borderRadius: DesignTokens.radiusXl,
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.walletBalance, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        PriceText(
                          formatMoney(wallet.balance.round()),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          DateFormat.yMMMd().add_jm().format(wallet.lastUpdated.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.recentTransactions,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<WalletTxFilter>(
                  segments: [
                    ButtonSegment(value: WalletTxFilter.all, label: Text(l10n.walletFilterAll)),
                    ButtonSegment(value: WalletTxFilter.credits, label: Text(l10n.walletFilterCredits)),
                    ButtonSegment(value: WalletTxFilter.debits, label: Text(l10n.walletFilterDebits)),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
                const SizedBox(height: 12),
                if (txs.isEmpty)
                  EmptyState(icon: Icons.history_rounded, title: l10n.recentTransactions)
                else
                  ...txs.map((tx) {
                    final color = tx.isCredit ? context.priceColor : c.error;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassSurface(
                        borderRadius: DesignTokens.radiusLg,
                        onTap: () => _showDetails(context, tx),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(_iconFor(tx), color: color, size: 20),
                          ),
                          title: Text(
                            tx.typeLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.displayReason,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (tx.bookingReference != null && tx.bookingReference!.isNotEmpty)
                                Text(
                                  tx.bookingReference!,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.primary),
                                ),
                              Text(
                                DateFormat.yMMMd().add_jm().format(tx.createdAt.toLocal()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              PriceText(
                                '${tx.isCredit ? '+' : ''}${formatMoney(tx.amount.abs())}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Icon(Icons.chevron_right_rounded, color: context.inactiveColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
