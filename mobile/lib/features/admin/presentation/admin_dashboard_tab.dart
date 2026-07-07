import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/admin_stats.dart';
import '../../../core/providers/admin_providers.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../services/admin_service.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../../widgets/stat_card.dart';
import '../../shell/shell_layout.dart';

class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final statsAsync = ref.watch(adminStatsProvider(key));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.adminDashboard)),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: e is AdminForbiddenException ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
          title: l10n.retry,
          subtitle: e is AdminForbiddenException ? e.message : e.toString(),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminStatsProvider(key)),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.spaceLg,
              DesignTokens.spaceLg,
              DesignTokens.spaceLg,
              ShellLayout.bottomInset(context),
            ),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: StatCard(
                      label: l10n.totalUsers,
                      value: stats.totalUsers.toString(),
                      icon: Icons.people_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatCard(
                      label: l10n.totalOwners,
                      value: stats.totalOwners.toString(),
                      icon: Icons.business_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatCard(
                      label: l10n.totalFields,
                      value: stats.totalFields.toString(),
                      icon: Icons.stadium_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatCard(
                      label: l10n.totalBookings,
                      value: stats.totalBookings.toString(),
                      icon: Icons.event_note_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassSurface(
                borderRadius: DesignTokens.radiusXl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.platformRevenue,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      formatMoney(stats.totalRevenueIqd),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          maxY: _chartMaxY(stats),
                          barGroups: [
                            _bar(0, stats.totalUsers.toDouble()),
                            _bar(1, stats.totalOwners.toDouble()),
                            _bar(2, stats.totalFields.toDouble()),
                            _bar(3, stats.totalBookings.toDouble()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _chartMaxY(AdminStats stats) {
    final peak = [
      stats.totalUsers,
      stats.totalOwners,
      stats.totalFields,
      stats.totalBookings,
    ].fold<int>(0, (a, b) => a > b ? a : b);
    return peak.toDouble() + 1;
  }

  BarChartGroupData _bar(int x, double y) => BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y > 0 ? y : 0.1,
            color: DesignTokens.primaryTeal,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
}
