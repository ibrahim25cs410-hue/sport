import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// حارس مرمى مع انقضاض نحو الكرة.
class Goalkeeper extends PositionComponent {
  Goalkeeper({required Vector2 goalSize}) : _goalSize = goalSize;

  final Vector2 _goalSize;

  double _targetX = 0;
  double _reactDelay = 0;
  bool _diving = false;
  double _diveProgress = 0;
  double _diveDir = 0;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.bottomCenter;
    size = Vector2(_goalSize.x * 0.24, _goalSize.y * 0.62);
    position = Vector2(_goalSize.x * 0.5, _goalSize.y * 0.96);
  }

  void defendAgainst(double shotX, {double difficulty = 0.72}) {
    _reactDelay = 0.1;
    final error = (math.Random().nextDouble() - 0.5) * (1 - difficulty) * 0.35;
    final clamped = (shotX + error).clamp(0.08, 0.92);
    _targetX = clamped * _goalSize.x;
    _diveDir = (clamped - 0.5).sign;
    _diving = true;
    _diveProgress = 0;
  }

  void reset() {
    _diving = false;
    _reactDelay = 0;
    _diveProgress = 0;
    position.x = _goalSize.x * 0.5;
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_reactDelay > 0) {
      _reactDelay -= dt;
      return;
    }
    if (!_diving) return;

    final dx = _targetX - position.x;
    position.x += dx * math.min(1, dt * 8.5);
    _diveProgress = (_diveProgress + dt * 2.8).clamp(0.0, 1.0);
    angle = _diveDir * _diveProgress * 0.9;

    if (dx.abs() < 4 && _diveProgress >= 0.85) {
      _diving = false;
    }
  }

  @override
  void render(Canvas canvas) {
    final dive = _diveProgress;
    final dir = _diveDir;
    final w = size.x;
    final h = size.y;
    final cx = w * 0.5;
    final groundY = h * 0.94;
    final drop = dive * h * 0.3;

    canvas.save();
    canvas.translate(cx + dir * dive * w * 0.3, groundY - drop);
    canvas.rotate(dir * dive * 1.0);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 4), width: w * 0.8, height: 7),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );

    final jersey = const Color(0xFFFFB300);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -h * 0.42), width: 24, height: 28), const Radius.circular(6)),
      Paint()..color = jersey,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -h * 0.2), width: 22, height: 12), const Radius.circular(4)),
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawCircle(Offset(0, -h * 0.58), 8.5, Paint()..color = const Color(0xFFFFCC80));

    final reach = 18 + dive * 24;
    final armY = -h * 0.46;
    final glove = Paint()..color = const Color(0xFF43A047);
    final arm = Paint()
      ..color = jersey
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-10, armY), Offset(-reach, armY - dir * 8), arm);
    canvas.drawCircle(Offset(-reach, armY - dir * 8), 6, glove);
    canvas.drawLine(Offset(10, armY), Offset(reach, armY + dir * 6), arm);
    canvas.drawCircle(Offset(reach, armY + dir * 6), 6, glove);

    canvas.restore();
  }

  bool blocks(Vector2 ballCenter, double ballRadius) {
    final left = position.x - size.x * 0.55;
    final right = position.x + size.x * 0.55;
    final top = position.y - size.y;
    final bottom = position.y;
    final inX = ballCenter.x + ballRadius > left && ballCenter.x - ballRadius < right;
    final inY = ballCenter.y + ballRadius > top && ballCenter.y - ballRadius < bottom;
    return inX && inY;
  }
}
