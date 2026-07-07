import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/booking_actions_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../models/field.dart';
import '../../../router/app_router.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/field_card.dart';
import '../../../widgets/skeleton_loaders.dart';
import '../../shell/shell_layout.dart';
import '../../shell/shell_state.dart';

class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final fieldsAsync = ref.watch(fieldsListProvider(key));
    final fields = fieldsAsync.valueOrNull ?? <Field>[];
    final loading = fieldsAsync.isLoading && fields.isEmpty;
    final favorites = ref.watch(shellProvider.select((s) => s.favorites));
    final favoriteFields = fields.where((f) => favorites.contains(f.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTab)),
      body: loading
          ? const FieldsListSkeleton()
          : RefreshIndicator(
              color: context.accentColor,
              onRefresh: () async {
                ref.invalidate(fieldsListProvider(key));
                await ref.read(fieldsListProvider(key).future);
              },
              child: favoriteFields.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: ShellLayout.listPadding(context),
                      children: [
                        RefreshableEmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: l10n.noFavorites,
                          subtitle: l10n.noFavoritesHint,
                          onRefresh: () async {
                            ref.invalidate(fieldsListProvider(key));
                            await ref.read(fieldsListProvider(key).future);
                          },
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: ShellLayout.listPadding(context),
                      itemCount: favoriteFields.length,
                      itemBuilder: (_, i) => FieldCard(
                        field: favoriteFields[i],
                        isFavorite: true,
                        onFavoriteToggle: () => ref.read(shellProvider.notifier).toggleFavorite(favoriteFields[i].id),
                        onTap: () => context.goField(favoriteFields[i]),
                      ),
                    ),
            ),
    );
  }
}
