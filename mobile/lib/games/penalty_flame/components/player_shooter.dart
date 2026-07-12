import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PlayerAnimState { idle, kicking, celebrating }

/// لاعب يسدّد — رسم مخصص مع حركة ركل.
class PlayerShooter extends PositionComponent {
  PlayerShooter({required Vector2 fieldSize}) : _fieldSize = fieldSize;

  final Vector2 _fieldSize;
  PlayerAnimState state = PlayerAnimState.idle;
  double _kickT = 0;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.bottomCenter;
    position = Vector2(_fieldSize.x * 0.5, _fieldSize.y * 0.9);
    size = Vector2(_fieldSize.x * 0.14, _fieldSize.y * 0.2);
  }

  void kick() {
    state = PlayerAnimState.kicking;
    _kickT = 0;
  }

  void reset() => state = PlayerAnimState.idle;

  @override
  void update(double dt) {
    super.update(dt);
    if (state != PlayerAnimState.kicking) return;
    _kickT += dt;
    if (_kickT >= 0.28) {
      state = PlayerAnimState.idle;
      _kickT = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final kick = state == PlayerAnimState.kicking ? (_kickT / 0.28).clamp(0.0, 1.0) : 0.0;
    final w = size.x;
    final h = size.y;
    final cx = w * 0.5;
    final groundY = h * 0.96;

    canvas.save();
    canvas.translate(cx, groundY);
    canvas.rotate(-kick * 0.12);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 2), width: w * 0.7, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );

    _leg(canvas, Offset(-7, 0), kick: kick, kicking: false);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -h * 0.38), width: 22, height: 30), const Radius.circular(6)),
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -h * 0.22), width: 24, height: 14), const Radius.circular(4)),
      Paint()..color = const Color(0xFF0D47A1),
    );
    canvas.drawCircle(Offset(0, -h * 0.56), 9, Paint()..color = const Color(0xFFFFCC80));
    _leg(canvas, Offset(8, -h * 0.18), kick: kick, kicking: true);
    canvas.restore();
  }

  void _leg(Canvas canvas, Offset hip, {required double kick, required bool kicking}) {
    final leg = Paint()
      ..color = const Color(0xFF0D47A1)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    if (!kicking) {
      canvas.drawLine(hip, Offset(hip.dx - 4, 0), leg);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(hip.dx - 4, 2), width: 14, height: 7), const Radius.circular(3)),
        Paint()..color = Colors.white,
      );
    } else {
      final knee = Offset(hip.dx + 10 + kick * 18, hip.dy + 8 - kick * 4);
      final foot = Offset(hip.dx + 22 + kick * 28, hip.dy + 14 - kick * 22);
      canvas.drawLine(hip, knee, leg);
      canvas.drawLine(knee, foot, leg);
      canvas.drawCircle(foot, 5.5, Paint()..color = Colors.white);
    }
  }
}
