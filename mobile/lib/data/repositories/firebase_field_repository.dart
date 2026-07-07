import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../domain/entities/field_entity.dart';
import '../../domain/repositories/field_repository.dart';
import '../models/firestore_mappers.dart';

class FirebaseFieldRepository implements FieldRepository {
  FirebaseFieldRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<FieldEntity>> watchFields({FieldFilter? filter}) {
    Query<Map<String, dynamic>> q = _db.collection(FirestorePaths.fields).orderBy('averageRating', descending: true);
    if (filter?.availableOnly == true) {
      q = q.where('isAvailable', isEqualTo: true);
    }
    if (filter?.category != null) {
      q = q.where('category', isEqualTo: filter!.category!.value);
    }
    return q.snapshots().map((snap) {
      var list = snap.docs.map(FirestoreMappers.fieldFromDoc).toList();
      list = _applyClientFilter(list, filter);
      return list;
    });
  }

  List<FieldEntity> _applyClientFilter(List<FieldEntity> list, FieldFilter? filter) {
    if (filter == null) return list;
    var out = list;
    final q = filter.query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      out = out.where((f) => f.name.toLowerCase().contains(q) || f.address.toLowerCase().contains(q)).toList();
    }
    if (filter.minPrice != null) out = out.where((f) => f.pricePerHour >= filter.minPrice!).toList();
    if (filter.maxPrice != null) out = out.where((f) => f.pricePerHour <= filter.maxPrice!).toList();
    if (filter.minRating != null) out = out.where((f) => f.averageRating >= filter.minRating!).toList();
    if (filter.indoor != null) out = out.where((f) => f.isIndoor == filter.indoor).toList();
    switch (filter.sortBy) {
      case FieldSortBy.priceAsc:
        out.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
      case FieldSortBy.priceDesc:
        out.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
      case FieldSortBy.rating:
        out.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case FieldSortBy.distance:
        out.sort((a, b) => (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99));
      case FieldSortBy.popularity:
        out.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return out;
  }

  @override
  Future<FieldEntity?> getField(String id) async {
    final doc = await _db.collection(FirestorePaths.fields).doc(id).get();
    if (!doc.exists) return null;
    return FirestoreMappers.fieldFromDoc(doc);
  }

  @override
  Future<List<FieldEntity>> getPopularFields({int limit = 10}) async {
    final snap = await _db
        .collection(FirestorePaths.fields)
        .orderBy('reviewCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(FirestoreMappers.fieldFromDoc).toList();
  }
}
