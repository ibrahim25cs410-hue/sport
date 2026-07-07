import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/language_switcher.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../../widgets/theme_mode_switcher.dart';
import '../../shell/shell_layout.dart';

/// Admin settings tab — profile shortcuts and logout.
class AdminSettingsTab extends ConsumerWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.settings)),
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
                    user.name.isNotEmpty ? user.name[0] : 'A',
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
                      Text(user.roleLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.accentColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.language_rounded, color: c.primary),
            title: Text(l10n.language),
            onTap: () => showLanguagePickerSheet(context),
          ),
          const ThemeModeSwitcher(),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: c.error),
            title: Text(l10n.logout, style: TextStyle(color: c.error)),
            onTap: () async {
              await ref.read(authServiceProvider).logout();
              await ref.read(authProvider.notifier).clearSession();
              if (context.mounted) context.goLoginClearStack();
            },
          ),
        ],
      ),
    );
  }
}
