import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/l10n_extension.dart';
import '../utils/validators.dart';
import '../widgets/auth_entry_app_bar_actions.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// تسجيل دخول مفصول حسب الدور — مستخدم أو صاحب ملعب.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.expectedRole});

  /// `user` أو `owner`
  final String expectedRole;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool get _isOwner => widget.expectedRole == 'owner';

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    final ok = await auth.login(
      _email.text.trim(),
      _pass.text,
      expectedRole: widget.expectedRole,
    );
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
    return RtlScaffold(
      appBar: AppBar(
        title: Text(_isOwner ? l10n.loginAsOwner : l10n.loginAsUser),
        actions: const [AuthEntryAppBarActions()],
      ),
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
              Text(
                _isOwner ? l10n.loginAsOwner : l10n.loginAsUser,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                _isOwner ? l10n.loginOwnerSubtitle : l10n.loginUserSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              EmailFormField(controller: _email, validator: validateEmail),
              const SizedBox(height: 16),
              PasswordFormField(controller: _pass, validator: (v) => validatePassword(v)),
              const SizedBox(height: 28),
              LoadingButton(
                loading: loading,
                onPressed: _submit,
                label: l10n.login,
                icon: Icons.login_rounded,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _isOwner ? context.goRegisterOwner() : context.goRegisterUser(),
                child: Text(_isOwner ? l10n.goToOwnerRegister : l10n.goToUserRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
