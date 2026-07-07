import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Goal frame — replace rects with sprite sheet when art is ready.
class GoalFrame extends PositionComponent {
  GoalFrame({required Vector2 size}) {
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    final postPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    add(RectangleComponent(size: size, paint: netPaint));
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(6, size.y),
      paint: postPaint,
    ));
    add(RectangleComponent(
      position: Vector2(size.x - 6, 0),
      size: Vector2(6, size.y),
      paint: postPaint,
    ));
    add(RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(size.x, 6),
      paint: postPaint,
    ));
  }
}
