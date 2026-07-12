import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/field.dart';
import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';

class SelectedFieldController extends Notifier<Field?> {
  @override
  Field? build() => null;

  void select(Field field) => state = field;
  void clear() => state = null;
}

final selectedFieldProvider = NotifierProvider<SelectedFieldController, Field?>(SelectedFieldController.new);

class ShellState {
  const ShellState({
    this.search = '',
    this.favorites = const {},
    this.selectedCategory,
    this.favoritesLoaded = false,
    this.minPrice = 0,
    this.maxPrice = defaultMaxPrice,
    this.minRating = 0,
    this.availableOnly = false,
  });

  /// سقف افتراضي عالٍ حتى لا تُخفى الملاعب غالية السعر عن المستخدم.
  static const double defaultMaxPrice = 5000000;

  final String search;
  final Set<int> favorites;
  final String? selectedCategory;
  final bool favoritesLoaded;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final bool availableOnly;

  bool get hasActiveFilters =>
      minPrice > 0 || maxPrice < defaultMaxPrice || minRating > 0 || availableOnly;

  ShellState copyWith({
    String? search,
    Set<int>? favorites,
    String? selectedCategory,
    bool clearCategory = false,
    bool? favoritesLoaded,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? availableOnly,
    bool resetFilters = false,
  }) =>
      ShellState(
        search: search ?? this.search,
        favorites: favorites ?? this.favorites,
        selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
        favoritesLoaded: favoritesLoaded ?? this.favoritesLoaded,
        minPrice: resetFilters ? 0 : (minPrice ?? this.minPrice),
        maxPrice: resetFilters ? defaultMaxPrice : (maxPrice ?? this.maxPrice),
        minRating: resetFilters ? 0 : (minRating ?? this.minRating),
        availableOnly: resetFilters ? false : (availableOnly ?? this.availableOnly),
      );
}

class ShellController extends Notifier<ShellState> {
  static const _favoritesKey = 'riyada_favorite_field_ids';
  Timer? _searchDebounce;

  @override
  ShellState build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    Future.microtask(_loadFavorites);
    return const ShellState();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_favoritesKey) ?? [];
      final ids = raw.map(int.tryParse).whereType<int>().toSet();
      state = state.copyWith(favorites: ids, favoritesLoaded: true);
    } catch (_) {
      state = state.copyWith(favoritesLoaded: true);
    }
  }

  Future<void> _persistFavorites(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids.map((e) => e.toString()).toList());
  }

  void setSearch(String v, {bool immediate = false}) {
    _searchDebounce?.cancel();
    if (immediate || v.isEmpty) {
      state = state.copyWith(search: v);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      state = state.copyWith(search: v);
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    state = state.copyWith(search: '');
  }
  void setCategory(String? cat) => state = state.copyWith(selectedCategory: cat, clearCategory: cat == null);

  void setFieldFilters({
    required double minPrice,
    required double maxPrice,
    required double minRating,
    required bool availableOnly,
  }) {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      availableOnly: availableOnly,
    );
  }

  void resetFieldFilters() => state = state.copyWith(resetFilters: true);

  /// فلتر سريع: ملاعب متاحة للحجز الآن.
  void applyAvailableNowFilter() {
    state = state.copyWith(resetFilters: true, availableOnly: true);
  }

  /// فلتر سريع: ملاعب معتمدة (تقييم 4+).
  void applyCertifiedFilter() {
    state = state.copyWith(resetFilters: true, minRating: 4);
  }

  void toggleFavorite(int id) {
    final next = Set<int>.from(state.favorites);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(favorites: next);
    _persistFavorites(next);
  }
}

final shellProvider = NotifierProvider<ShellController, ShellState>(ShellController.new);

class ShellTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final shellTabProvider = NotifierProvider<ShellTabController, int>(ShellTabController.new);

class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({super.key, required this.selected, required this.onSelected, required this.labels});

  final String? selected;
  final ValueChanged<String?> onSelected;
  final List<(String id, String label, IconData icon)> labels;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label, icon) = labels[i];
          final active = selected == id;
          return FilterChip(
            avatar: Icon(icon, size: 16, color: active ? DesignTokens.onNeon : context.accentColor),
            label: Text(label),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => onSelected(active ? null : id),
            selectedColor: c.primary,
            labelStyle: TextStyle(
              color: active ? DesignTokens.onNeon : context.inactiveColor,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: c.surfaceVariant,
            side: BorderSide(color: active ? c.primary : c.outlineVariant),
          );
        },
      ),
    );
  }
}

List<Field> filterFields(
  List<Field> fields, {
  String search = '',
  String? category,
  double minPrice = 0,
  double maxPrice = double.infinity,
  double minRating = 0,
  bool availableOnly = false,
}) {
  var list = fields;
  if (search.isNotEmpty) {
    final q = search.toLowerCase();
    list = list.where((f) => f.name.toLowerCase().contains(q) || f.address.toLowerCase().contains(q)).toList();
  }
  if (category != null) {
    list = list.where((f) => _matchesCategory(f, category)).toList();
  }
  list = list.where((f) => f.pricePerHour >= minPrice && f.pricePerHour <= maxPrice).toList();
  if (minRating > 0) list = list.where((f) => f.averageRating >= minRating).toList();
  if (availableOnly) list = list.where((f) => f.pricePerHour > 0).toList();
  return list;
}

bool _matchesCategory(Field field, String category) {
  final text = '${field.name} ${field.address}'.toLowerCase();
  return switch (category) {
    '5v5' => text.contains('5') || text.contains('خمس'),
    '7v7' => text.contains('7') || text.contains('سبع'),
    '11v11' => text.contains('11') || text.contains('احدى') || text.contains('كامل'),
    'indoor' => text.contains('داخل') || text.contains('indoor') || text.contains('صالة'),
    'outdoor' => !text.contains('داخل') && !text.contains('indoor') && !text.contains('صالة'),
    _ => true,
  };
}
