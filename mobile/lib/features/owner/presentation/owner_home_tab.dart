import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/payment_policy.dart';
import '../../../core/providers/owner_payment_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../providers/booking_provider.dart';
import '../../../router/app_router.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/error_messages.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/stat_card.dart';
import '../../shell/shell_layout.dart';

/// الرئيسية للمالك — ملخص سريع.
class OwnerHomeTab extends ConsumerWidget {
  const OwnerHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final dashAsync = ref.watch(ownerDashboardProvider(key));
    final outstanding =
        ref.watch(ownerPaymentAccountProvider(key).select((a) => a.valueOrNull?.outstandingAmount ?? 0));
    final dash = dashAsync.valueOrNull;
    final loading = dashAsync.isLoading && dash == null;
    final errorText = dashAsync.hasError ? friendlyErrorMessage(dashAsync.error) : null;

    Future<void> refresh() async {
      await ref.read(ownerDashboardProvider(key).notifier).refreshPreservingData();
      ref.invalidate(ownerPaymentAccountProvider(key));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ownerDashboard)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dashAsync.hasError && dash == null
              ? RefreshableEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: errorText ?? l10n.connectionLost,
                  subtitle: l10n.retry,
                  onRefresh: refresh,
                )
              : dash == null
                  ? RefreshableEmptyState(
                      icon: Icons.stadium_outlined,
                      title: l10n.noFields,
                      subtitle: l10n.noFieldsHint,
                      onRefresh: refresh,
                    )
                  : RefreshIndicator(
                      onRefresh: refresh,
                      child: ListView(
                        padding: ShellLayout.contentPadding(context),
                        children: [
                          RepaintBoundary(
                            child: FinanceSummaryCard(
                              totalRevenue: dash.totalRevenue,
                              commission: dash.appCommission,
                              netRevenue: dash.netRevenue,
                              pendingCount: dash.pendingCount,
                            ),
                          ),
                          if (PaymentPolicy.electronicPaymentsEnabled && outstanding > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
                              child: FilledButton.icon(
                                onPressed: () => context.goOwnerCommissionCheckout(),
                                icon: const Icon(Icons.payment_rounded),
                                label: Text(l10n.payCommissionAmount(formatMoney(outstanding))),
                              ),
                            ),
                          if (dash.field != null)
                            Padding(
                              padding: const EdgeInsets.only(top: DesignTokens.spaceLg),
                              child: Text(dash.field!.name, style: Theme.of(context).textTheme.titleLarge),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: DesignTokens.spaceLg),
                              child: Text(l10n.noFields, style: Theme.of(context).textTheme.titleMedium),
                            ),
                          const SizedBox(height: DesignTokens.spaceMd),
                          OutlinedButton.icon(
                            onPressed: () => context.goAddField(),
                            icon: const Icon(Icons.add_business_rounded),
                            label: Text(l10n.addNewField),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
