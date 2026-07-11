import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/error_messages.dart';
import '../utils/l10n_extension.dart';
import '../utils/validators.dart';
import '../widgets/auth_entry_app_bar_actions.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../router/app_router.dart';

class RegisterOwnerScreen extends ConsumerStatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  ConsumerState<RegisterOwnerScreen> createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends ConsumerState<RegisterOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _fieldName = TextEditingController();
  final _address = TextEditingController();
  final _fieldPhone = TextEditingController();
  final _price = TextEditingController();
  String? _stadiumImageBase64;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass, _fieldName, _address, _fieldPhone, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStadiumImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 75);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _stadiumImageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final auth = ref.read(authProvider.notifier);
    final ok = await auth.registerOwner({
      'name': _name.text.trim(),
      'email': _email.text.trim().toLowerCase(),
      'phone': normalizeIraqiPhone(_phone.text),
      'password': _pass.text,
      'stadiumName': _fieldName.text.trim(),
      'stadiumAddress': _address.text.trim(),
      'stadiumPhone': normalizeIraqiPhone(_fieldPhone.text),
      'pricePerHour': int.tryParse(_price.text) ?? 0,
      if (_stadiumImageBase64 != null) 'stadiumImage': _stadiumImageBase64,
    });
    if (!mounted) return;
    if (!ok) {
      showAppError(context, ref.read(authProvider).error ?? l10n.registerError);
      return;
    }
    context.goHomeAfterAuth(isAdmin: false, isOwner: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loading = ref.watch(authProvider).loading;
    return RtlScaffold(
      appBar: AppBar(
        title: Text(l10n.registerOwner),
        actions: const [AuthEntryAppBarActions()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _sectionTitle(Icons.person_outline_rounded, l10n.yourInfo),
            TextFormField(controller: _name, decoration: InputDecoration(labelText: l10n.nameShort), validator: (v) => validateRequired(v, label: l10n.nameShort)),
            const SizedBox(height: 12),
            EmailFormField(controller: _email, label: l10n.email, validator: validateEmail),
            const SizedBox(height: 12),
            PhoneFormField(controller: _phone, label: l10n.phone, validator: validateIraqiPhone),
            const SizedBox(height: 12),
            PasswordFormField(controller: _pass, validator: validatePassword, showStrength: true),
            const SizedBox(height: 24),
            _sectionTitle(Icons.stadium_outlined, l10n.fieldInfo),
            Center(
              child: GestureDetector(
                onTap: _pickStadiumImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: _stadiumImageBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(base64Decode(_stadiumImageBase64!.split(',').last), fit: BoxFit.cover, width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 36, color: context.colors.primaryLight),
                            const SizedBox(height: 8),
                            Text(l10n.addFieldPhoto, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _fieldName, decoration: InputDecoration(labelText: l10n.fieldNameLabel), validator: (v) => validateRequired(v, label: l10n.fieldNameLabel)),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: InputDecoration(labelText: l10n.addressLabel), validator: (v) => validateRequired(v, label: l10n.addressLabel)),
            const SizedBox(height: 12),
            PhoneFormField(controller: _fieldPhone, label: l10n.fieldPhoneLabel, validator: validateIraqiPhone),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: InputDecoration(labelText: l10n.pricePerHourLabel, prefixIcon: const Icon(Icons.payments_outlined)),
              keyboardType: TextInputType.number,
              validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1000 ? l10n.invalidPrice : null,
            ),
            const SizedBox(height: 28),
            LoadingButton(loading: loading, onPressed: _submit, label: l10n.createOwnerAccount, icon: Icons.storefront_rounded),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.goLoginOwner(),
              child: Text(l10n.goToOwnerLogin),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    final c = context.colors;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: c.primary, size: 22),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.primary)),
          ],
        ),
      );
  }
}
