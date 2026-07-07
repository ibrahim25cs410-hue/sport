import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? c.primary;
    final valueColor = color ?? context.priceColor;
    final child = Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: DesignTokens.cardShadow(accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: valueColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
    return expanded ? Expanded(child: child) : child;
  }
}

class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    super.key,
    required this.totalRevenue,
    required this.commission,
    required this.netRevenue,
    required this.pendingCount,
  });

  final int totalRevenue;
  final int commission;
  final int netRevenue;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.heroBannerGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.cardShadow(c.primary, elevated: true),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: c.onInverse),
              const SizedBox(width: 8),
              Text(l10n.financialSummary, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: c.onInverse)),
              const Spacer(),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingCount ${l10n.waiting}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c.primaryDark),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _format(netRevenue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: c.onInverse, fontWeight: FontWeight.w800),
          ),
          Text(l10n.netRevenue, style: TextStyle(color: c.onInverseMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            l10n.platformCommissionRate,
            style: TextStyle(color: c.onInverseMuted.withValues(alpha: 0.85), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStat(context, l10n.grandTotal, _format(totalRevenue))),
              const SizedBox(width: 12),
              Expanded(child: _miniStat(context, l10n.appCommission, _format(commission))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.onInverse.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: c.onInverse, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label, style: TextStyle(color: c.onInverseMuted, fontSize: 11)),
        ],
      ),
    );
  }

  String _format(int n) => '${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} د.ع';
}
