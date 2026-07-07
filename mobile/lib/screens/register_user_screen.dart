import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/l10n_extension.dart';
import '../theme/riyada_theme_extension.dart';
import '../theme/app_theme.dart';
import '../utils/api_logger.dart';
import '../utils/error_messages.dart';
import '../utils/validators.dart';
import '../widgets/api_server_settings_card.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../router/app_router.dart';

class RegisterUserScreen extends ConsumerStatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  ConsumerState<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends ConsumerState<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  String? _imageBase64;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) {
      showAppWarningSnackBar(context, l10n.completeAllFields);
      return;
    }
    final auth = ref.read(authProvider.notifier);
    final body = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': normalizeIraqiPhone(_phone.text),
      'province': 'نينوى',
      'password': _pass.text,
      if (_imageBase64 != null) 'image': _imageBase64,
    };
    apiLog('تسجيل مستخدم — إرسال الطلب', ref.read(apiClientProvider).baseUrl);
    try {
      final ok = await auth.registerUser(body);
      if (!mounted) return;
      if (!ok) {
        final err = ref.read(authProvider).error ?? l10n.registerError;
        apiLogError('تسجيل مستخدم — فشل', err);
        showAppError(context, err);
        return;
      }
      apiLog('تسجيل مستخدم — نجح');
      context.goHomeAfterAuth(isAdmin: false, isOwner: false);
    } catch (e, st) {
      apiLogError('تسجيل مستخدم — استثناء', e, st);
      if (mounted) showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).loading;
    final l10n = context.l10n;
    final c = context.colors;
    return RtlScaffold(
      appBar: AppBar(title: Text(l10n.registerUser)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: c.primary.withValues(alpha: 0.1),
                      backgroundImage: _imageBase64 != null ? MemoryImage(base64Decode(_imageBase64!.split(',').last)) : null,
                      child: _imageBase64 == null ? Icon(Icons.person_rounded, size: 48, color: c.primary) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: c.primary,
                        child: Icon(Icons.camera_alt_rounded, size: 16, color: context.colors.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(l10n.addProfilePhoto, style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.name, prefixIcon: const Icon(Icons.badge_outlined)),
              validator: (v) => validateRequired(v, label: l10n.nameShort),
            ),
            const SizedBox(height: 14),
            EmailFormField(controller: _email, validator: validateEmail),
            const SizedBox(height: 14),
            PhoneFormField(controller: _phone, validator: validateIraqiPhone),
            const SizedBox(height: 14),
            PasswordFormField(controller: _pass, validator: validatePassword, showStrength: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: c.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('${l10n.province}: ${l10n.provinceNineveh}', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (kDebugMode) const ApiServerSettingsCard(),
            if (kDebugMode) const SizedBox(height: 16),
            LoadingButton(loading: loading, onPressed: _submit, label: l10n.createAccountLogin, icon: Icons.person_add_rounded),
          ],
        ),
      ),
    );
  }
}
