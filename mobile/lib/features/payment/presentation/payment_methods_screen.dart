import 'package:flutter/material.dart';

import '../../../domain/enums/owner_payment_gateway.dart';
import '../../../services/payment_preferences_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/l10n_extension.dart';
import 'payment_widgets.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  OwnerPaymentGateway _selected = OwnerPaymentGateway.zainCash;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final gateway = await PaymentPreferencesService.loadGateway();
    if (!mounted) return;
    setState(() {
      _selected = gateway;
      _loading = false;
    });
  }

  Future<void> _save(OwnerPaymentGateway gateway) async {
    setState(() {
      _selected = gateway;
      _saving = true;
    });
    await PaymentPreferencesService.saveGateway(gateway);
    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnackBar(context, context.l10n.paymentMethodSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentMethods)),
      body: !PaymentPreferencesService.electronicPaymentsEnabled
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments_rounded, size: 52),
                    const SizedBox(height: DesignTokens.spaceMd),
                    Text(
                      isArabic ? 'الدفع نقداً في الملعب حالياً' : 'Cash at venue is currently available',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Text(
                      isArabic ? 'الدفع الإلكتروني سيتوفر قريباً' : 'Electronic payments are coming soon',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.paymentMethodsHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  Expanded(
                    child: PaymentGatewaySelector(
                      selected: _selected,
                      saving: _saving,
                      onSelected: _save,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
