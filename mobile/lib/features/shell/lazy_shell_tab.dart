import 'package:flutter/material.dart';

/// يحمّل التبويب عند أول زيارة فقط — يقلّل بناء 5 شاشات دفعة واحدة.
class LazyShellTab extends StatefulWidget {
  const LazyShellTab({
    super.key,
    required this.index,
    required this.activeIndex,
    required this.child,
  });

  final int index;
  final int activeIndex;
  final Widget child;

  @override
  State<LazyShellTab> createState() => _LazyShellTabState();
}

class _LazyShellTabState extends State<LazyShellTab> {
  bool _visited = false;

  @override
  void initState() {
    super.initState();
    if (widget.activeIndex == widget.index) _visited = true;
  }

  @override
  void didUpdateWidget(LazyShellTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex == widget.index) _visited = true;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeIndex == widget.index;
    if (!_visited) return const SizedBox.shrink();

    return TickerMode(
      enabled: active,
      child: Offstage(
        offstage: !active,
        child: widget.child,
      ),
    );
  }
}
