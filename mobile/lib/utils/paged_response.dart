/// Unwraps API list responses — supports legacy `[...]` and paginated `{ items: [...] }`.
List<T> unwrapPagedList<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (data is List) {
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
  if (data is Map<String, dynamic>) {
    final items = data['items'];
    if (items is List) {
      return items.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  return const [];
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
