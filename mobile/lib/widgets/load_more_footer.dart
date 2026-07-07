import 'package:flutter/material.dart';

/// Triggers [onLoadMore] when the user scrolls near the bottom.
class LoadMoreScrollNotification extends StatelessWidget {
  const LoadMoreScrollNotification({
    super.key,
    required this.onLoadMore,
    required this.hasMore,
    required this.loading,
    this.child,
  });

  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool loading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return child ?? const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: loading
            ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))
            : TextButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('تحميل المزيد'),
              ),
      ),
    );
  }
}
