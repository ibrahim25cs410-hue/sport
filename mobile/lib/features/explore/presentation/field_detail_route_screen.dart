import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/field.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../screens/field_detail_screen.dart';

/// يحمّل الملعب من المعرّف عند فتح الرابط مباشرة.
class FieldDetailRouteScreen extends ConsumerStatefulWidget {
  const FieldDetailRouteScreen({super.key, required this.fieldId, this.initialField});

  final int fieldId;
  final Field? initialField;

  @override
  ConsumerState<FieldDetailRouteScreen> createState() => _FieldDetailRouteScreenState();
}

class _FieldDetailRouteScreenState extends ConsumerState<FieldDetailRouteScreen> {
  Field? _field;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _field = widget.initialField;
    if (_field != null) {
      _loading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadField());
    }
  }

  Future<void> _loadField() async {
    try {
      final field = await ref.read(authServiceProvider).getField(widget.fieldId);
      if (!mounted) return;
      setState(() {
        _field = field;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_field != null) {
      return FieldDetailScreen(field: _field!);
    }
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              Text(_error ?? context.l10n.fieldLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(context.l10n.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
