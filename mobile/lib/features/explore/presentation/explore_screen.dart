import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/booking_actions_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../models/field.dart';
import '../../../providers/session_key.dart';
import '../../../router/app_router.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/field_card.dart';
import '../../../widgets/field_filters_sheet.dart';
import '../../../widgets/premium/premium_home_ui.dart';
import '../../../widgets/skeleton_loaders.dart';
import '../../shell/shell_layout.dart';
import '../../shell/shell_state.dart';
import 'fields_map_view.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _mapView = false;

  Future<void> _refreshFields(UserSessionKey key) async {
    ref.invalidate(fieldsListProvider(key));
    await ref.read(fieldsListProvider(key).future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final shell = ref.watch(shellProvider);
    final fieldsAsync = ref.watch(fieldsListProvider(key));
    final fields = fieldsAsync.valueOrNull ?? <Field>[];
    final filtered = filterFields(
      fields,
      search: shell.search,
      category: shell.selectedCategory,
      minPrice: shell.minPrice,
      maxPrice: shell.maxPrice,
      minRating: shell.minRating,
      availableOnly: shell.availableOnly,
    );
    final favorites = shell.favorites;
    final loading = fieldsAsync.isLoading && fields.isEmpty;

    final hasMapFields = fields.any((f) => f.hasLocation);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.exploreTab),
        actions: [
          if (hasMapFields)
            IconButton(
              icon: Icon(_mapView ? Icons.view_list_rounded : Icons.map_outlined),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _mapView = !_mapView);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          PremiumSearchBar(
            onChanged: (v) => ref.read(shellProvider.notifier).setSearch(v),
            onFilter: () => showFieldFiltersSheet(context, ref),
            hasQuery: shell.search.isNotEmpty,
            hasActiveFilters: shell.hasActiveFilters,
            onClear: () => ref.read(shellProvider.notifier).clearSearch(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: loading
                ? const FieldsListSkeleton()
                : fieldsAsync.hasError && fields.isEmpty
                    ? RefreshableEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: l10n.connectionLost,
                        subtitle: l10n.noFieldsHint,
                        onRefresh: () => _refreshFields(key),
                      )
                    : _mapView
                        ? FieldsMapView(
                            fields: filtered,
                            onFieldTap: (f) => context.goField(f),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _refreshFields(key),
                            color: context.accentColor,
                            child: filtered.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: ShellLayout.listPadding(context),
                                    children: [
                                      RefreshableEmptyState(
                                        icon: Icons.search_off_rounded,
                                        title: l10n.noFields,
                                        subtitle: l10n.noFieldsHint,
                                        onRefresh: () => _refreshFields(key),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: ShellLayout.listPadding(context),
                                    cacheExtent: 480,
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) => FieldCard(
                                      field: filtered[i],
                                      isFavorite: favorites.contains(filtered[i].id),
                                      onFavoriteToggle: () => ref.read(shellProvider.notifier).toggleFavorite(filtered[i].id),
                                      onTap: () => context.goField(filtered[i]),
                                    ),
                                  ),
                          ),
          ),
        ],
      ),
    );
  }
}
