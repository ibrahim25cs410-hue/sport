import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../utils/validators.dart';
import '../widgets/form_fields.dart';

/// شاشة إضافة ملعب جديد لصاحب الملعب — يظهر للمستخدمين فوراً بعد الحفظ.
class AddFieldScreen extends ConsumerStatefulWidget {
  const AddFieldScreen({super.key});

  @override
  ConsumerState<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends ConsumerState<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _price = TextEditingController();
  String? _imageBase64;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 75);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final price = int.tryParse(_price.text.trim()) ?? 0;
    if (price < 1000) {
      showAppError(context, l10n.invalidPrice);
      return;
    }

    final ok = await ref.read(authProvider.notifier).createField(
          name: _name.text.trim(),
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          pricePerHour: price,
          image: _imageBase64,
        );

    if (!mounted) return;
    if (!ok) {
      showAppError(context, ref.read(authProvider).error ?? l10n.retry);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.fieldAddedSuccess)),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loading = ref.watch(authProvider.select((s) => s.loading));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addNewField)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: _imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        child: Image.memory(
                          base64Decode(_imageBase64!.split(',').last),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 36, color: context.accentColor),
                            const SizedBox(height: 8),
                            Text(l10n.addFieldPhoto),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.fieldNameLabel),
              validator: (v) => validateRequired(v, label: l10n.fieldNameLabel),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextFormField(
              controller: _address,
              decoration: InputDecoration(labelText: l10n.addressLabel),
              validator: (v) => validateRequired(v, label: l10n.addressLabel),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            PhoneFormField(controller: _phone, label: l10n.fieldPhoneLabel, validator: validateIraqiPhone),
            const SizedBox(height: DesignTokens.spaceSm),
            TextFormField(
              controller: _price,
              decoration: InputDecoration(labelText: l10n.pricePerHourLabel),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1000) return l10n.invalidPrice;
                return null;
              },
            ),
            const SizedBox(height: DesignTokens.spaceXl),
            LoadingButton(
              loading: loading,
              onPressed: _submit,
              label: l10n.addNewField,
              icon: Icons.add_business_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
