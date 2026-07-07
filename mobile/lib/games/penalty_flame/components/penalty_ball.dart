import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ball with simple velocity integration — no external physics engine required.
class PenaltyBall extends PositionComponent {
  PenaltyBall({required this.fieldSize});

  final Vector2 fieldSize;
  Vector2 velocity = Vector2.zero();
  bool inFlight = false;
  bool resolved = false;

  late final CircleComponent _circle;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    final radius = fieldSize.x * 0.035;
    size = Vector2.all(radius * 2);
    _circle = CircleComponent(
      radius: radius,
      paint: Paint()..color = Colors.white,
      children: [
        CircleComponent(
          radius: radius * 0.15,
          position: Vector2(radius * 0.35, radius * 0.35),
          paint: Paint()..color = Colors.black12,
        ),
      ],
    );
    add(_circle);
    resetToSpot();
  }

  void resetToSpot() {
    inFlight = false;
    resolved = false;
    velocity = Vector2.zero();
    position = Vector2(fieldSize.x * 0.5, fieldSize.y * 0.78);
  }

  void shoot(Vector2 direction, double power) {
    if (inFlight) return;
    inFlight = true;
    resolved = false;
    final normalized = direction.normalized();
    velocity = normalized * power.clamp(280, 720);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!inFlight || resolved) return;

    position += velocity * dt;
    velocity *= 0.992;

    if (position.y < fieldSize.y * 0.08 || position.x < 0 || position.x > fieldSize.x) {
      inFlight = false;
      resolved = true;
    }
  }
}
