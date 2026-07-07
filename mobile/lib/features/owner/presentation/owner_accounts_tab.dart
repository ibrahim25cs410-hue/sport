import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/owner_payment_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../router/app_router.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/error_messages.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/price_text.dart';
import '../../../widgets/fintech/fintech_card.dart';

import '../../shell/shell_layout.dart';

/// حسابات المالك — عمولة المنصة والمدفوعات.
class OwnerAccountsTab extends ConsumerWidget {
  const OwnerAccountsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final accountAsync = ref.watch(ownerPaymentAccountProvider(key));
    final account = accountAsync.valueOrNull;
    final loading = accountAsync.isLoading && account == null;

    Future<void> refresh() => ref.read(ownerPaymentAccountProvider(key).notifier).refreshPreservingData();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountsTab)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : accountAsync.hasError && account == null
              ? RefreshableEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.connectionLost,
                  subtitle: friendlyErrorMessage(accountAsync.error),
                  onRefresh: refresh,
                )
              : account == null
                  ? RefreshableEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.accountsTab,
                      subtitle: l10n.noFieldsHint,
                      onRefresh: refresh,
                    )
              : RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                padding: ShellLayout.contentPadding(context),
                children: [
                  FintechCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.outstandingCommission, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          formatMoney(account.outstandingAmount),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: c.primary),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.goOwnerCommissionCheckout(),
                          icon: const Icon(Icons.payment_rounded),
                          label: Text(l10n.payCommission),
                        ),
                      ],
                    ),
                  ),
                  if (account.paidInvoices.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.spaceLg),
                    Text(l10n.paidInvoices, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...account.paidInvoices.take(5).map(
                          (i) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(i.title),
                            trailing: PriceText(formatMoney(i.amount)),
                          ),
                        ),
                  ],
                ],
              ),
            ),
    );
  }
}
