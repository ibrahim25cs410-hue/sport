import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/core/paging/paged_list_state.dart';

void main() {
  test('inferHasMore returns true when page is full', () {
    expect(inferHasMore(20, 20), isTrue);
    expect(inferHasMore(19, 20), isFalse);
  });

  test('PagedListState copyWith preserves unchanged fields', () {
    const state = PagedListState<int>(items: [1, 2], page: 2, hasMore: false);
    final next = state.copyWith(loadingMore: true);
    expect(next.items, [1, 2]);
    expect(next.page, 2);
    expect(next.hasMore, isFalse);
    expect(next.loadingMore, isTrue);
  });
}
