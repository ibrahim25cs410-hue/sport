/// Generic paginated list state for Riverpod notifiers.
class PagedListState<T> {
  const PagedListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.loadingMore = false,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  PagedListState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      PagedListState<T>(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

const defaultPageSize = 20;

bool inferHasMore(int fetchedCount, int limit) => fetchedCount >= limit;
