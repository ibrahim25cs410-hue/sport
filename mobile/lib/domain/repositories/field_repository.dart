import '../entities/field_entity.dart';
import '../enums/field_category.dart';

enum FieldSortBy { popularity, priceAsc, priceDesc, rating, distance }

class FieldFilter {
  const FieldFilter({
    this.query,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxDistanceKm,
    this.indoor,
    this.availableOnly = false,
    this.category,
    this.sortBy = FieldSortBy.popularity,
  });

  final String? query;
  final int? minPrice;
  final int? maxPrice;
  final double? minRating;
  final double? maxDistanceKm;
  final bool? indoor;
  final bool availableOnly;
  final FieldCategory? category;
  final FieldSortBy sortBy;
}

abstract class FieldRepository {
  Stream<List<FieldEntity>> watchFields({FieldFilter? filter});
  Future<FieldEntity?> getField(String id);
  Future<List<FieldEntity>> getPopularFields({int limit = 10});
}
