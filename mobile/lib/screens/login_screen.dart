import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../utils/validators.dart';
import '../widgets/api_server_settings_card.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    final ok = await auth.login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (!ok) {
      showAppError(context, state.error ?? context.l10n.saveFailed);
      return;
    }
    context.goHomeAfterAuth(isAdmin: state.user!.isAdmin, isOwner: state.user!.isOwner);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).loading;
    final l10n = context.l10n;
    final c = context.colors;
    return RtlScaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(child: AppLogo(size: 72, showLabel: false)),
              const SizedBox(height: 16),
              Text(l10n.welcomeBack, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              Text(l10n.loginSubtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              EmailFormField(controller: _email, validator: validateEmail),
              const SizedBox(height: 16),
              PasswordFormField(controller: _pass, validator: (v) => validatePassword(v)),
              const SizedBox(height: 28),
              LoadingButton(loading: loading, onPressed: _submit, label: l10n.login, icon: Icons.login_rounded),
              const SizedBox(height: 16),
              if (kDebugMode) const ApiServerSettingsCard(),
              if (kDebugMode) const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.goRegisterUser(),
                child: Text(l10n.registerUserCta),
              ),
              TextButton(
                onPressed: () => context.goRegisterOwner(),
                child: Text(l10n.registerOwnerCta),
              ),
              const SizedBox(height: 12),
              if (kDebugMode) ...[
                SectionHeader(title: l10n.demoAccounts),
                _demoBtn(Icons.storefront_rounded, l10n.demoOwner, 'owner@test.com', '123456', c.primaryLight),
                const SizedBox(height: 8),
                _demoBtn(Icons.person_rounded, l10n.demoUser, 'user@test.com', '123456', c.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoBtn(IconData icon, String label, String email, String pass, Color color) => Card(
        child: InkWell(
          onTap: () {
            _email.text = email;
            _pass.text = pass;
            _submit();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.titleMedium),
                      Text(email, style: Theme.of(context).textTheme.bodyMedium, textDirection: TextDirection.ltr),
                    ],
                  ),
                ),
                const Icon(Icons.login_rounded, size: 20),
              ],
            ),
          ),
        ),
      );
}
