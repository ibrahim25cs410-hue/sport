import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/booking_actions_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../models/field.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/session_key.dart';
import '../../../router/app_router.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_motion.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/error_messages.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/phone_launcher.dart';
import '../../../widgets/common.dart';
import '../../../widgets/connectivity_banner.dart';
import '../../../widgets/field_card.dart';
import '../../../widgets/field_filters_sheet.dart';
import '../../../widgets/load_more_footer.dart';
import '../../../widgets/premium/premium_home_ui.dart';
import '../../../widgets/skeleton_loaders.dart';
import '../../shell/shell_layout.dart';
import '../../shell/shell_state.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _fieldsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final user = ref.read(authProvider).user;
      if (user == null) return;
      final key = UserSessionKey(client: ref.read(apiClientProvider), userId: user.id);
      ref.invalidate(fieldsListProvider(key));
    }
  }

  Future<void> _refresh(UserSessionKey key) async {
    ref.invalidate(fieldsListProvider(key));
    await ref.read(fieldsListProvider(key).future);
  }

  void _scrollToFields() {
    HapticFeedback.selectionClick();
    final target = _fieldsSectionKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: RiyadaMotion.medium,
      curve: RiyadaMotion.standardCurve,
      alignment: 0.05,
    );
  }

  void _openBookingsTab() {
    HapticFeedback.selectionClick();
    ref.read(shellTabProvider.notifier).select(1);
  }

  void _openFilters() {
    HapticFeedback.selectionClick();
    showFieldFiltersSheet(context, ref);
  }

  void _applyAvailableNow() {
    HapticFeedback.selectionClick();
    ref.read(shellProvider.notifier).applyAvailableNowFilter();
    _scrollToFields();
  }

  void _applyCertified() {
    HapticFeedback.selectionClick();
    ref.read(shellProvider.notifier).applyCertifiedFilter();
    _scrollToFields();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final key = watchSessionKey(ref);
    if (user == null || key == null) return const SizedBox.shrink();

    ref.listen<int>(shellTabProvider, (prev, next) {
      if (next == 0 && prev != null && prev != 0) {
        ref.invalidate(fieldsListProvider(key));
      }
    });

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fieldsAsync = ref.watch(fieldsListProvider(key));
    final notificationsAsync = ref.watch(userNotificationsProvider(key));
    final shell = ref.watch(shellProvider);
    final search = shell.search;
    final category = shell.selectedCategory;
    final favorites = shell.favorites;

    final fields = fieldsAsync.valueOrNull ?? <Field>[];
    final unread = (notificationsAsync.valueOrNull ?? []).where((n) => !n.isRead).length;
    final filtered = filterFields(
      fields,
      search: search,
      category: category,
      minPrice: shell.minPrice,
      maxPrice: shell.maxPrice,
      minRating: shell.minRating,
      availableOnly: shell.availableOnly,
    );
    final loading = fieldsAsync.isLoading && fields.isEmpty;

    final categories = [
      ('5v5', l10n.category5v5, Icons.groups_2_rounded),
      ('7v7', l10n.category7v7, Icons.groups_rounded),
      ('11v11', l10n.category11v11, Icons.stadium_rounded),
      ('indoor', l10n.categoryIndoor, Icons.roofing_rounded),
      ('outdoor', l10n.categoryOutdoor, Icons.wb_sunny_outlined),
    ];

    return ConnectivityBanner(
      child: ColoredBox(
        color: Colors.transparent,
        child: loading
            ? const FieldsListSkeleton()
            : RefreshIndicator(
                onRefresh: () => _refresh(key),
                color: context.accentColor,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PremiumHomeAppBar(
                            userName: user.name,
                            unreadCount: unread,
                            onNotifications: () => context.goNotifications(),
                          ),
                          PremiumSearchBar(
                            onChanged: (v) => ref.read(shellProvider.notifier).setSearch(v),
                            onFilter: _openFilters,
                            hasQuery: search.isNotEmpty,
                            hasActiveFilters: shell.hasActiveFilters,
                            onClear: () => ref.read(shellProvider.notifier).clearSearch(),
                          ),
                          PremiumHeroBanner(onBook: _scrollToFields),
                          const SizedBox(height: DesignTokens.spaceMd),
                          CategoryChipsRow(
                            selected: category,
                            labels: categories,
                            onSelected: (c) => ref.read(shellProvider.notifier).setCategory(c),
                          ),
                          const SizedBox(height: DesignTokens.spaceMd),
                          PremiumFeaturesGrid(
                            onOffers: () {
                              HapticFeedback.selectionClick();
                              context.goPenaltyShootout();
                            },
                            onBookings: _openBookingsTab,
                            onAvailable: _applyAvailableNow,
                            onCertified: _applyCertified,
                            onSupport: () {
                              HapticFeedback.selectionClick();
                              launchPhoneCall('07700000000');
                            },
                          ),
                          Padding(
                            key: _fieldsSectionKey,
                            padding: const EdgeInsets.fromLTRB(
                              DesignTokens.spaceLg,
                              DesignTokens.spaceLg,
                              DesignTokens.spaceLg,
                              4,
                            ),
                            child: Text(
                              l10n.popularFields,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (fieldsAsync.hasError && fields.isEmpty)
                      SliverFillRemaining(
                        child: RefreshableEmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: l10n.connectionLost,
                          subtitle: friendlyErrorMessage(fieldsAsync.error),
                          onRefresh: () => _refresh(key),
                        ),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        child: RefreshableEmptyState(
                          icon: Icons.stadium_outlined,
                          title: l10n.noFields,
                          subtitle: l10n.noFieldsHint,
                          onRefresh: () => _refresh(key),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            if (i == filtered.length) {
                              final notifier = ref.read(fieldsListProvider(key).notifier);
                              return LoadMoreScrollNotification(
                                hasMore: notifier.hasMore,
                                loading: notifier.loadingMore,
                                onLoadMore: () => notifier.loadMore(),
                              );
                            }
                            final field = filtered[i];
                            return RepaintBoundary(
                              child: FieldCard(
                                field: field,
                                isFavorite: favorites.contains(field.id),
                                onFavoriteToggle: () => ref.read(shellProvider.notifier).toggleFavorite(field.id),
                                onTap: () => context.goField(field),
                              ),
                            );
                          },
                          childCount: filtered.length + (ref.read(fieldsListProvider(key).notifier).hasMore ? 1 : 0),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: PremiumPromoBanner(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.goPenaltyShootout();
                        },
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: ShellLayout.bottomInset(context))),
                  ],
                ),
              ),
      ),
    );
  }
}
