import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:url_launcher/url_launcher.dart';

import '../../../config/payment_policy.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../router/app_router.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/language_switcher.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../../widgets/theme_mode_switcher.dart';
import '../../shell/shell_layout.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final user = ref.watch(authProvider).user;
    final isArabic = legacy.Provider.of<LocaleProvider>(context).isArabic;
    if (user == null) return const SizedBox.shrink();

    final chevron = isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTab)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.spaceLg,
          DesignTokens.spaceLg,
          DesignTokens.spaceLg,
          ShellLayout.bottomInset(context),
        ),
        children: [
          GlassSurface(
            borderRadius: DesignTokens.radiusXl,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: c.primary.withValues(alpha: 0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                      Text(user.email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant)),
                      Text(user.roleLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.goProfile()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _tile(context, chevron, Icons.person_outline_rounded, l10n.profile, () => context.goProfile()),
          _tile(context, chevron, Icons.language_rounded, l10n.language, () => showLanguagePickerSheet(context)),
          if (PaymentPolicy.electronicPaymentsEnabled)
            _tile(context, chevron, Icons.payment_rounded, l10n.paymentMethods, () => context.goPaymentMethods()),
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
                  child: Text(l10n.darkMode, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const ThemeModeSwitcher(),
              ],
            ),
          ),
          _tile(context, chevron, Icons.history_rounded, l10n.bookingHistory, () => context.goBookingHistory()),
          _tile(context, chevron, Icons.notifications_outlined, l10n.notifications, () => context.goNotifications()),
          _tile(context, chevron, Icons.sports_soccer_rounded, l10n.penaltyShootout, () => context.goPenaltyShootout()),
          _tile(context, chevron, Icons.privacy_tip_outlined, l10n.privacyPolicy, () async {
            final uri = Uri.parse('https://riyada.iq/privacy');
            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
          }),
          const SizedBox(height: 8),
          _tile(context, chevron, Icons.logout_rounded, l10n.logout, () async {
            await ref.read(authServiceProvider).logout();
            await ref.read(authProvider.notifier).clearSession();
            if (context.mounted) context.goLoginClearStack();
          }, danger: true),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData chevron,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final c = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: danger ? c.error : c.primary),
        title: Text(label, style: TextStyle(color: danger ? c.error : c.onSurface)),
        trailing: Icon(chevron),
        onTap: onTap,
      ),
    );
  }
}
