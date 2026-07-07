import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/field.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../shell/shell_layout.dart';

/// خريطة الملاعب — OpenStreetMap بدون مفتاح Google Maps.
class FieldsMapView extends StatefulWidget {
  const FieldsMapView({
    super.key,
    required this.fields,
    required this.onFieldTap,
  });

  final List<Field> fields;
  final void Function(Field field) onFieldTap;

  static const _mosulCenter = LatLng(36.3350, 43.1189);

  @override
  State<FieldsMapView> createState() => _FieldsMapViewState();
}

class _FieldsMapViewState extends State<FieldsMapView> {
  final MapController _controller = MapController();

  List<Field> get _located => widget.fields.where((f) => f.hasLocation).toList();

  LatLng get _initialCenter {
    if (_located.isEmpty) return FieldsMapView._mosulCenter;
    final f = _located.first;
    return LatLng(f.latitude!, f.longitude!);
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final c = context.colors;
    return _located
        .map(
          (f) => Marker(
            point: LatLng(f.latitude!, f.longitude!),
            width: 44,
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => widget.onFieldTap(f),
                child: Tooltip(
                  message: f.name,
                  child: Icon(Icons.location_on_rounded, color: c.primary, size: 40),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bottom = ShellLayout.bottomInset(context);

    if (_located.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
        child: GlassSurface(
          borderRadius: DesignTokens.radiusXl,
          blur: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_rounded, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(l10n.noFields, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.noFieldsHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 12,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'iq.riyada.riyada',
            ),
            MarkerLayer(markers: _buildMarkers(context)),
          ],
        ),
      ),
    );
  }
}
