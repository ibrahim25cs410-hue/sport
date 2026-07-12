import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shell/shell_state.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';

/// يفتح ورقة الفلاتر ويحدّث [shellProvider] عند التطبيق.
Future<void> showFieldFiltersSheet(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final shell = ref.read(shellProvider);

  var minPrice = shell.minPrice;
  var maxPrice = shell.maxPrice;
  var minRating = shell.minRating;
  var availableOnly = shell.availableOnly;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: theme.colorScheme.surface,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: 20,
            end: 20,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.exploreFilters, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(l10n.filterPrice),
              RangeSlider(
                values: RangeValues(
                  minPrice,
                  maxPrice.clamp(minPrice, ShellState.defaultMaxPrice),
                ),
                max: ShellState.defaultMaxPrice,
                divisions: 50,
                activeColor: context.accentColor,
                onChanged: (v) => setModal(() {
                  minPrice = v.start;
                  maxPrice = v.end;
                }),
              ),
              Text('${l10n.filterRating}: ${minRating.toStringAsFixed(1)}'),
              Slider(
                value: minRating,
                max: 5,
                divisions: 10,
                activeColor: context.accentColor,
                onChanged: (v) => setModal(() => minRating = v),
              ),
              SwitchListTile(
                title: Text(l10n.availableNow),
                value: availableOnly,
                activeTrackColor: context.accentColor.withValues(alpha: 0.45),
                onChanged: (v) => setModal(() => availableOnly = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(shellProvider.notifier).resetFieldFilters();
                        Navigator.pop(ctx);
                      },
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(shellProvider.notifier).setFieldFilters(
                              minPrice: minPrice,
                              maxPrice: maxPrice,
                              minRating: minRating,
                              availableOnly: availableOnly,
                            );
                        Navigator.pop(ctx);
                      },
                      child: Text(l10n.applyFilters),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
