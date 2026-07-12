/// Unwraps API list responses — supports legacy `[...]` and paginated `{ items: [...] }`.
List<T> unwrapPagedList<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  List<dynamic> raw;
  if (data is List) {
    raw = data;
  } else if (data is Map<String, dynamic>) {
    final items = data['items'];
    if (items is! List) return const [];
    raw = items;
  } else {
    return const [];
  }
  final out = <T>[];
  for (final e in raw) {
    if (e is! Map) continue;
    try {
      out.add(fromJson(Map<String, dynamic>.from(e)));
    } catch (_) {
      // تخطّي عنصر تالف بدل إسقاط القائمة كاملة
    }
  }
  return out;
}

bool pagedHasNextPage(dynamic data) {
  if (data is Map<String, dynamic>) return data['hasNextPage'] == true;
  return false;
}

int? pagedTotalCount(dynamic data) {
  if (data is Map<String, dynamic>) {
    final total = data['totalCount'];
    if (total is int) return total;
  }
  return null;
}
