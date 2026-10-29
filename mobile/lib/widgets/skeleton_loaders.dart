import 'package:flutter/material.dart';
import '../theme/riyada_theme_extension.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final animation = _ShimmerAnimation.of(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 + t * 2, 0),
              colors: [
                c.surfaceVariant,
                c.primary.withValues(alpha: 0.08),
                c.surfaceVariant,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerScope extends StatefulWidget {
  const _ShimmerScope({required this.child});

  final Widget child;

  @override
  State<_ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<_ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerAnimation(animation: _controller, child: widget.child);
}

class _ShimmerAnimation extends InheritedNotifier<Animation<double>> {
  const _ShimmerAnimation({
    required Animation<double> animation,
    required super.child,
  }) : super(notifier: animation);

  static Animation<double> of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerAnimation>()!
        .notifier!;
  }
}

class FieldsListSkeleton extends StatelessWidget {
  const FieldsListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: count,
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(height: 20, width: 180),
                      SizedBox(height: 12),
                      ShimmerBox(height: 14, width: double.infinity),
                      SizedBox(height: 8),
                      ShimmerBox(height: 14, width: 120),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class BookingsListSkeleton extends StatelessWidget {
  const BookingsListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: count,
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(height: 18, width: 160),
                      SizedBox(height: 12),
                      ShimmerBox(height: 14, width: double.infinity),
                      SizedBox(height: 8),
                      ShimmerBox(height: 14, width: 200),
                      SizedBox(height: 12),
                      ShimmerBox(
                        height: 36,
                        width: double.infinity,
                        radius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class NotificationsListSkeleton extends StatelessWidget {
  const NotificationsListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: count,
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: const [
                  ShimmerBox(height: 44, width: 44, radius: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(height: 14, width: double.infinity),
                        SizedBox(height: 8),
                        ShimmerBox(height: 12, width: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class StatsRowSkeleton extends StatelessWidget {
  const StatsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: const [
            Expanded(child: ShimmerBox(height: 72, radius: 16)),
            SizedBox(width: 10),
            Expanded(child: ShimmerBox(height: 72, radius: 16)),
            SizedBox(width: 10),
            Expanded(child: ShimmerBox(height: 72, radius: 16)),
          ],
        ),
      ),
    );
  }
}

class OwnerDashboardSkeleton extends StatelessWidget {
  const OwnerDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  ShimmerBox(height: 120, radius: 16),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ShimmerBox(height: 72, radius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: ShimmerBox(height: 72, radius: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(height: 18, width: 160),
                        SizedBox(height: 12),
                        ShimmerBox(height: 14, width: double.infinity),
                        SizedBox(height: 8),
                        ShimmerBox(height: 14, width: 200),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: ShimmerBox(height: 40, radius: 12)),
                            SizedBox(width: 8),
                            Expanded(child: ShimmerBox(height: 40, radius: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              childCount: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleSkeleton extends StatelessWidget {
  const ScheduleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ShimmerBox(height: 220, width: double.infinity, radius: 0),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(height: 24, width: 200),
                        SizedBox(height: 16),
                        ShimmerBox(height: 14, width: double.infinity),
                        SizedBox(height: 8),
                        ShimmerBox(height: 14, width: 160),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ShimmerBox(height: 20, width: 140),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  12,
                  (_) => const ShimmerBox(height: 36, width: 96, radius: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
