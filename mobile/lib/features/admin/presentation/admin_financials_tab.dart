import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/admin_owner.dart';
import '../../../core/providers/admin_providers.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../services/admin_service.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../../widgets/stat_card.dart';
import '../../shell/shell_layout.dart';

class AdminFinancialsTab extends ConsumerStatefulWidget {
  const AdminFinancialsTab({super.key});

  @override
  ConsumerState<AdminFinancialsTab> createState() => _AdminFinancialsTabState();
}

class _AdminFinancialsTabState extends ConsumerState<AdminFinancialsTab> {
  final _busyFields = <int>{};
  final _busyOwners = <int>{};

  Future<void> _showOwnerTopUp(AdminOwner owner) async {
    final l10n = context.l10n;
    final amountCtrl = TextEditingController(text: '50000');
    final noteCtrl = TextEditingController();
    final key = watchSessionKey(ref);
    if (key == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminTopUpWallet),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(owner.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.topUpAmount),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(labelText: l10n.adminTopUpNote),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.topUpWallet)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final amount = int.tryParse(amountCtrl.text.replaceAll(',', '').trim());
    if (amount == null || amount < 1000) {
      showAppWarningSnackBar(context, l10n.topUpAmount);
      return;
    }

    setState(() => _busyOwners.add(owner.id));
    try {
      await ref.read(adminServiceProvider).adminTopUpOwner(
            ownerId: owner.id,
            amountIqd: amount,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );
      if (mounted) showAppSnackBar(context, l10n.walletTopUpSuccess);
    } on AdminForbiddenException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      amountCtrl.dispose();
      noteCtrl.dispose();
      if (mounted) setState(() => _busyOwners.remove(owner.id));
    }
  }

  Future<void> _toggleField(int fieldId) async {
    final key = watchSessionKey(ref);
    if (key == null) return;
    setState(() => _busyFields.add(fieldId));
    try {
      await ref.read(adminServiceProvider).toggleFieldStatus(fieldId);
      ref.invalidate(adminFieldsProvider(key));
      if (mounted) showAppSnackBar(context, 'تم تحديث حالة الملعب');
    } on AdminForbiddenException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busyFields.remove(fieldId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final financialAsync = ref.watch(adminFinancialStatsProvider(key));
    final fieldsAsync = ref.watch(adminFieldsProvider(key));
    final ownersAsync = ref.watch(adminOwnersProvider(key));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.financialSummary)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminFinancialStatsProvider(key));
          ref.invalidate(adminFieldsProvider(key));
          ref.invalidate(adminOwnersProvider(key));
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            DesignTokens.spaceLg,
            DesignTokens.spaceLg,
            DesignTokens.spaceLg,
            ShellLayout.bottomInset(context),
          ),
          children: [
            financialAsync.when(
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
              ),
              error: (e, _) => EmptyState(
                icon: e is AdminForbiddenException ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                title: l10n.retry,
                subtitle: e.toString(),
              ),
              data: (stats) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: StatCard(
                      label: l10n.totalRevenue,
                      value: formatMoney(stats.totalRevenueIqd),
                      icon: Icons.payments_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatCard(
                      label: l10n.platformRevenue,
                      value: formatMoney(stats.platformCommissionIqd),
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatCard(
                      label: l10n.totalBookings,
                      value: stats.paidBookings.toString(),
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.adminTopUpWallet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adminTopUpWalletHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            ownersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: l10n.retry,
                subtitle: e.toString(),
              ),
              data: (owners) {
                if (owners.isEmpty) {
                  return EmptyState(icon: Icons.people_outline_rounded, title: l10n.adminTopUpWallet);
                }
                return Column(
                  children: owners.map((owner) {
                    final busy = _busyOwners.contains(owner.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassSurface(
                        borderRadius: DesignTokens.radiusLg,
                        child: ListTile(
                          title: Text(owner.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${owner.email} · ${owner.fieldCount} ${l10n.totalFields}'),
                          trailing: busy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.account_balance_wallet_rounded),
                                  tooltip: l10n.topUpWallet,
                                  onPressed: () => _showOwnerTopUp(owner),
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              l10n.totalFields,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            fieldsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: l10n.retry,
                subtitle: e.toString(),
              ),
              data: (fields) {
                if (fields.isEmpty) {
                  return EmptyState(icon: Icons.stadium_rounded, title: l10n.totalFields);
                }
                return Column(
                  children: fields.map((field) {
                    final busy = _busyFields.contains(field.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassSurface(
                        borderRadius: DesignTokens.radiusLg,
                        child: SwitchListTile(
                          title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${field.ownerName} · ${field.address}'),
                          value: field.isActive,
                          onChanged: busy ? null : (_) => _toggleField(field.id),
                          secondary: busy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  field.isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                                  color: field.isActive ? DesignTokens.primaryTeal : null,
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
