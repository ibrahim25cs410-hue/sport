import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../core/providers/booking_actions_provider.dart';

import '../../../core/utils/session_key_helper.dart';

import '../../../models/field.dart';

import '../../../providers/auth_provider.dart';

import '../../../providers/session_key.dart';

import '../../../router/app_router.dart';
import '../../../utils/l10n_extension.dart';

import '../../../widgets/common.dart';

import '../../../widgets/connectivity_banner.dart';

import '../../../widgets/field_card.dart';

import '../../../widgets/premium/premium_home_ui.dart';

import '../../../widgets/skeleton_loaders.dart';

import '../../shell/shell_layout.dart';

import '../../shell/shell_state.dart';



/// الرئيسية — بحث مباشر وقائمة ملاعب متناسقة مع الاستكشاف.

class SimpleHomeTab extends ConsumerWidget {

  const SimpleHomeTab({super.key});



  Future<void> _refresh(WidgetRef ref, UserSessionKey key) async {

    ref.invalidate(fieldsListProvider(key));

    await ref.read(fieldsListProvider(key).future);

  }



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final user = ref.watch(authProvider.select((a) => a.user));

    final key = watchSessionKey(ref);

    if (user == null || key == null) return const SizedBox.shrink();



    final l10n = context.l10n;

    final fieldsAsync = ref.watch(fieldsListProvider(key));

    final shell = ref.watch(shellProvider);

    final fields = fieldsAsync.valueOrNull ?? <Field>[];

    final filtered = filterFields(fields, search: shell.search);

    final loading = fieldsAsync.isLoading && fields.isEmpty;



    return ConnectivityBanner(

      child: Scaffold(

        appBar: AppBar(

          title: Text(l10n.hello(user.name.split(' ').first)),

          actions: [

            IconButton(

              icon: const Icon(Icons.notifications_outlined),

              onPressed: () => context.goNotifications(),

            ),

          ],

        ),

        body: Column(

          children: [

            Padding(

              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),

              child: PremiumSearchBar(

                onChanged: (v) => ref.read(shellProvider.notifier).setSearch(v),

                onFilter: () => ref.read(shellTabProvider.notifier).select(1),

                hasQuery: shell.search.isNotEmpty,

                onClear: () => ref.read(shellProvider.notifier).clearSearch(),

              ),

            ),

            Expanded(

              child: loading

                  ? const FieldsListSkeleton()

                  : RefreshIndicator(

                      onRefresh: () => _refresh(ref, key),

                      child: fieldsAsync.hasError && fields.isEmpty

                          ? ListView(

                              padding: ShellLayout.listPadding(context),

                              children: [

                                RefreshableEmptyState(

                                  icon: Icons.cloud_off_rounded,

                                  title: l10n.connectionLost,

                                  subtitle: l10n.noFieldsHint,

                                  onRefresh: () => _refresh(ref, key),

                                ),

                              ],

                            )

                          : filtered.isEmpty

                              ? ListView(

                                  padding: ShellLayout.listPadding(context),

                                  children: [

                                    RefreshableEmptyState(

                                      icon: Icons.stadium_outlined,

                                      title: l10n.noFields,

                                      subtitle: l10n.noFieldsHint,

                                      onRefresh: () => _refresh(ref, key),

                                    ),

                                  ],

                                )

                              : ListView.builder(

                                  padding: ShellLayout.listPadding(context),

                                  itemCount: filtered.length,

                                  itemBuilder: (_, i) {

                                    final field = filtered[i];

                                    return RepaintBoundary(

                                      child: FieldCard(

                                        field: field,

                                        isFavorite: shell.favorites.contains(field.id),

                                        onFavoriteToggle: () =>

                                            ref.read(shellProvider.notifier).toggleFavorite(field.id),

                                        onTap: () => context.goField(field),

                                      ),

                                    );

                                  },

                                ),

                    ),

            ),

          ],

        ),

      ),

    );

  }

}


