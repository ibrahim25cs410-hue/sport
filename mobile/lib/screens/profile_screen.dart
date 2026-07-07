import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/error_messages.dart';
import '../utils/l10n_extension.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _pass;
  String? _imageBase64;
  String? _fieldImageBase64;
  bool _editing = false;
  bool _editingField = false;
  late final TextEditingController _fieldName;
  late final TextEditingController _fieldAddress;
  late final TextEditingController _fieldPhone;
  late final TextEditingController _fieldPrice;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _pass = TextEditingController();
    _fieldName = TextEditingController();
    _fieldAddress = TextEditingController();
    _fieldPhone = TextEditingController();
    _fieldPrice = TextEditingController();
  }

  void _syncFromAuth(AuthState auth) {
    if (_initialized) return;
    final u = auth.user!;
    _name.text = u.name;
    _phone.text = u.phone;
    _imageBase64 = u.image;
    final f = auth.ownerField;
    _fieldName.text = f?.name ?? '';
    _fieldAddress.text = f?.address ?? '';
    _fieldPhone.text = f?.phone ?? '';
    _fieldPrice.text = f != null ? '${f.pricePerHour}' : '';
    _fieldImageBase64 = f?.image;
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    _fieldName.dispose();
    _fieldAddress.dispose();
    _fieldPhone.dispose();
    _fieldPrice.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _pickFieldImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 75);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _fieldImageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _saveField() async {
    final l10n = context.l10n;
    if (ref.read(authProvider).ownerField == null) return;
    final price = int.tryParse(_fieldPrice.text) ?? 0;
    if (price < 1000) {
      showAppError(context, l10n.invalidPrice);
      return;
    }
    final ok = await ref.read(authProvider.notifier).updateField(
          name: _fieldName.text.trim(),
          address: _fieldAddress.text.trim(),
          phone: normalizeIraqiPhone(_fieldPhone.text),
          pricePerHour: price,
          image: _fieldImageBase64,
        );
    if (!mounted) return;
    if (!ok) {
      showAppError(context, ref.read(authProvider).error ?? l10n.saveFailed);
      return;
    }
    setState(() => _editingField = false);
    showAppSnackBar(context, l10n.fieldUpdated);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final ok = await ref.read(authProvider.notifier).updateProfile(
          name: _name.text.trim(),
          phone: normalizeIraqiPhone(_phone.text),
          image: _imageBase64,
          password: _pass.text.isEmpty ? null : _pass.text,
        );
    if (!mounted) return;
    if (!ok) {
      showAppError(context, ref.read(authProvider).error ?? l10n.saveFailed);
      return;
    }
    setState(() => _editing = false);
    _pass.clear();
    showAppSnackBar(context, l10n.profileUpdated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authProvider);
    final user = auth.user!;
    final ownerField = auth.ownerField;
    final loading = auth.loading;
    _syncFromAuth(auth);

    return RtlScaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _editing = true),
            )
          else
            TextButton(onPressed: () => setState(() => _editing = false), child: Text(l10n.cancel)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          children: [
            Center(
              child: Stack(
                children: [
                  UserAvatar(image: _imageBase64, name: user.name, radius: 56),
                  if (_editing)
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: context.colors.primaryLight,
                          child: Icon(Icons.camera_alt_rounded, size: 18, color: context.colors.onPrimary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(user.roleLabel, style: TextStyle(color: context.colors.primaryLight, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            if (_editing) ...[
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.nameShort, prefixIcon: const Icon(Icons.badge_outlined)),
                validator: (v) => (v == null || v.trim().length < 2) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              PhoneFormField(controller: _phone, validator: validateIraqiPhone),
              const SizedBox(height: DesignTokens.spaceSm),
              PasswordFormField(
                controller: _pass,
                label: l10n.newPasswordOptional,
                validator: (v) => v != null && v.isNotEmpty && v.length < 6 ? l10n.passwordMinChars : null,
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              LoadingButton(loading: loading, onPressed: _save, label: l10n.saveChanges, icon: Icons.save_rounded),
            ] else ...[
              _infoCard(Icons.person_outline_rounded, l10n.nameShort, user.name),
              _infoCard(Icons.email_outlined, l10n.email, user.email, ltr: true),
              _infoCard(Icons.phone_outlined, l10n.phone, user.phone),
              _infoCard(Icons.map_outlined, l10n.province, user.province),
              if (ownerField != null) ...[
                const SizedBox(height: DesignTokens.spaceMd),
                SectionHeader(
                  title: l10n.yourField,
                  trailing: IconButton(
                    icon: Icon(_editingField ? Icons.close_rounded : Icons.edit_rounded),
                    onPressed: () => setState(() => _editingField = !_editingField),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceMd),
                    child: _editingField
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GestureDetector(
                                onTap: _pickFieldImage,
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: context.colors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                  ),
                                  child: _fieldImageBase64 != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                          child: Image.memory(
                                            base64Decode(_fieldImageBase64!.split(',').last),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        )
                                      : const Center(child: Icon(Icons.add_a_photo_outlined, size: 32)),
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spaceSm),
                              TextFormField(controller: _fieldName, decoration: InputDecoration(labelText: l10n.fieldNameLabel)),
                              const SizedBox(height: DesignTokens.spaceSm),
                              TextFormField(controller: _fieldAddress, decoration: InputDecoration(labelText: l10n.addressLabel)),
                              const SizedBox(height: DesignTokens.spaceSm),
                              PhoneFormField(controller: _fieldPhone, label: l10n.fieldPhoneLabel),
                              const SizedBox(height: DesignTokens.spaceSm),
                              TextFormField(
                                controller: _fieldPrice,
                                decoration: InputDecoration(labelText: l10n.pricePerHourLabel),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: DesignTokens.spaceSm),
                              LoadingButton(loading: loading, onPressed: _saveField, label: l10n.saveField, icon: Icons.save_rounded),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ownerField.name, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: DesignTokens.spaceSm),
                              InfoTile(icon: Icons.location_on_outlined, text: ownerField.address),
                              InfoTile(icon: Icons.phone_outlined, text: ownerField.phone),
                              InfoTile(icon: Icons.payments_outlined, text: l10n.pricePerHourDisplay(ownerField.pricePerHour)),
                            ],
                          ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, {bool ltr = false}) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(icon, color: context.colors.primaryLight),
          title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium, textDirection: ltr ? TextDirection.ltr : null),
        ),
      );
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.image, required this.name, this.radius = 24});

  final String? image;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    if (image != null && image!.startsWith('data:')) {
      try {
        provider = MemoryImage(base64Decode(image!.split(',').last));
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.colors.primary.withValues(alpha: 0.15),
      backgroundImage: provider,
      child: provider == null
          ? Text(
              name.isNotEmpty ? name[0] : '?',
              style: TextStyle(fontSize: radius * 0.7, fontWeight: FontWeight.bold, color: context.colors.primary),
            )
          : null,
    );
  }
}
