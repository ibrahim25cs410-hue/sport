import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';

/// بطاقة ضبط عنوان الخادم — تظهر تلقائياً في وضع التطوير (debug).
class ApiServerSettingsCard extends ConsumerStatefulWidget {
  const ApiServerSettingsCard({super.key});

  @override
  ConsumerState<ApiServerSettingsCard> createState() => _ApiServerSettingsCardState();
}

class _ApiServerSettingsCardState extends ConsumerState<ApiServerSettingsCard> {
  late final TextEditingController _host;
  bool _testing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _host = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromClient());
  }

  void _syncFromClient() {
    if (!mounted) return;
    final url = ref.read(apiClientProvider).baseUrl;
    _host.text = url.replaceAll('/api', '').replaceAll('https://', '').replaceAll('http://', '');
    setState(() => _status = url);
  }

  @override
  void dispose() {
    _host.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _host.text.trim();
    final notifier = ref.read(authProvider.notifier);
    if (raw.isEmpty) {
      await notifier.setApiHost(null);
    } else if (raw.contains('://') || raw.contains(':')) {
      final url = raw.contains('://') ? raw : 'http://$raw';
      await notifier.setApiBaseUrl(url);
    } else {
      await notifier.setApiHost(raw);
    }
    if (!mounted) return;
    _syncFromClient();
    showAppSnackBar(context, context.l10n.serverSaved);
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final client = ref.read(apiClientProvider);
    try {
      await client.dio.get('/health', options: Options(extra: const {'skipGlobalLoading': true}));
      if (mounted) setState(() => _status = '✓ ${client.baseUrl}');
    } catch (_) {
      if (mounted) setState(() => _status = '✗ ${client.baseUrl}');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('ربط الخادم (تطوير)', style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'شغّل الخادم: .\\scripts\\run-api.ps1\n'
              'على الهاتف: أدخل IP الكمبيوتر (مثل 192.168.x.x:${ApiConfig.port})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _host,
              decoration: InputDecoration(
                labelText: l10n.apiHostLabel,
                hintText: l10n.apiHostHint,
                prefixIcon: const Icon(Icons.router_rounded),
                helperText: '${l10n.apiHostEmpty} (localhost:${ApiConfig.port})',
              ),
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
            ),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(_status!, style: Theme.of(context).textTheme.bodySmall, textDirection: TextDirection.ltr),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(l10n.save),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _testing ? null : _test,
                  child: _testing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_find_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
