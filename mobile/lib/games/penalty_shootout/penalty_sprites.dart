import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_logic.dart';
import 'penalty_theme.dart';

/// لاعب يسدّد ركلة جزاء — رسم مخصص بمنظور خلف الكرة.
class PenaltyPlayerSprite extends StatelessWidget {
  const PenaltyPlayerSprite({
    super.key,
    required this.palette,
    required this.kickProgress,
    this.width = 56,
  });

  final PenaltyPalette palette;
  final double kickProgress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.55;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(
        painter: _PlayerPainter(
          palette: palette,
          kick: kickProgress.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _PlayerPainter extends CustomPainter {
  _PlayerPainter({required this.palette, required this.kick});

  final PenaltyPalette palette;
  final double kick;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final groundY = size.height * 0.96;
    final lean = kick * 0.12;

    canvas.save();
    canvas.translate(cx, groundY);
    canvas.rotate(-lean);

    // ظل
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.22);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 2), width: size.width * 0.7, height: 8), shadow);

    // ساق ثابتة
    _drawLeg(canvas, Offset(-7, 0), planted: true, kick: kick);

    // جذع
    final bodyPaint = Paint()..color = const Color(0xFF1565C0);
    final bodyR = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -size.height * 0.38), width: 22, height: 30),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyR, bodyPaint);

    // شورت
    final shortsPaint = Paint()..color = const Color(0xFF0D47A1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -size.height * 0.22), width: 24, height: 14), const Radius.circular(4)),
      shortsPaint,
    );

    // رأس
    final skin = Paint()..color = const Color(0xFFFFCC80);
    canvas.drawCircle(Offset(0, -size.height * 0.56), 9, skin);
    final hair = Paint()..color = const Color(0xFF3E2723);
    canvas.drawArc(Rect.fromCircle(center: Offset(0, -size.height * 0.58), radius: 9), math.pi, math.pi, false, hair..style = PaintingStyle.stroke..strokeWidth = 5);

    // ذراعان للتوازن
    final arm = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final armSwing = kick * 0.9;
    canvas.drawLine(Offset(-12, -size.height * 0.42), Offset(-18 - armSwing * 8, -size.height * 0.28), arm);
    canvas.drawLine(Offset(12, -size.height * 0.42), Offset(16 + armSwing * 6, -size.height * 0.3), arm);

    // ساق التسديد
    _drawLeg(canvas, Offset(8, -size.height * 0.18), planted: false, kick: kick);

    canvas.restore();
  }

  void _drawLeg(Canvas canvas, Offset hip, {required bool planted, required double kick}) {
    final legPaint = Paint()
      ..color = const Color(0xFF0D47A1)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final boot = Paint()..color = Colors.white;

    if (planted) {
      canvas.drawLine(hip, Offset(hip.dx - 4, 0), legPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(hip.dx - 4, 2), width: 14, height: 7), const Radius.circular(3)), boot);
    } else {
      final knee = Offset(hip.dx + 10 + kick * 18, hip.dy + 8 - kick * 4);
      final foot = Offset(hip.dx + 22 + kick * 28, hip.dy + 14 - kick * 22);
      canvas.drawLine(hip, knee, legPaint);
      canvas.drawLine(knee, foot, legPaint);
      canvas.drawCircle(foot, 5.5, boot);
    }
  }

  @override
  bool shouldRepaint(covariant _PlayerPainter old) => old.kick != kick;
}

/// حارس مرمى — وضعية وقوف أو قفز/انقضاض.
class PenaltyGoalkeeperSprite extends StatelessWidget {
  const PenaltyGoalkeeperSprite({
    super.key,
    required this.palette,
    required this.diveProgress,
    required this.diveDirection,
    this.width = 52,
  });

  final PenaltyPalette palette;
  final double diveProgress;
  /// -1 يسار، 0 وسط، 1 يمين
  final double diveDirection;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.35;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(
        painter: _GoalkeeperPainter(
          palette: palette,
          dive: diveProgress.clamp(0.0, 1.0),
          direction: diveDirection.clamp(-1.0, 1.0),
        ),
      ),
    );
  }
}

class _GoalkeeperPainter extends CustomPainter {
  _GoalkeeperPainter({
    required this.palette,
    required this.dive,
    required this.direction,
  });

  final PenaltyPalette palette;
  final double dive;
  final double direction;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final groundY = size.height * 0.94;
    final eased = Curves.easeOutCubic.transform(dive);
    final tilt = direction * eased * 1.1;
    final drop = eased * size.height * 0.35;

    canvas.save();
    canvas.translate(cx + direction * eased * size.width * 0.35, groundY - drop);
    canvas.rotate(tilt);

    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 4 + drop * 0.3), width: size.width * (1 - eased * 0.3), height: 7),
      shadow,
    );

    final jersey = Paint()..color = const Color(0xFFFFB300);
    final shorts = Paint()..color = const Color(0xFF212121);
    final glove = Paint()..color = const Color(0xFF43A047);
    final skin = Paint()..color = const Color(0xFFFFCC80);

    // جسم مائل عند الانقضاض
    final bodyCenter = Offset(0, -size.height * (0.42 - eased * 0.12));
    final bodyW = 24.0 - eased * 4;
    final bodyH = 28.0 + eased * 6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: bodyCenter, width: bodyW, height: bodyH), const Radius.circular(6)),
      jersey,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -size.height * 0.2), width: 22, height: 12), const Radius.circular(4)),
      shorts,
    );

    // رأس
    final headY = -size.height * (0.58 - eased * 0.08);
    canvas.drawCircle(Offset(0, headY), 8.5, skin);

    // قفازات ممدودة
    final arm = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final reach = 18 + eased * 22;
    final armY = bodyCenter.dy - 4;

    // يد يسار
    canvas.drawLine(Offset(-10, armY), Offset(-reach, armY - direction * 8 - eased * 10), arm..color = jersey.color);
    canvas.drawCircle(Offset(-reach, armY - direction * 8 - eased * 10), 6, glove);

    // يد يمين
    canvas.drawLine(Offset(10, armY), Offset(reach, armY + direction * 6 + eased * 8), arm..color = jersey.color);
    canvas.drawCircle(Offset(reach, armY + direction * 6 + eased * 8), 6, glove);

    // ساقان
    final leg = Paint()
      ..color = shorts.color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    if (eased < 0.4) {
      canvas.drawLine(Offset(-6, -size.height * 0.12), Offset(-8, 0), leg);
      canvas.drawLine(Offset(6, -size.height * 0.12), Offset(8, 0), leg);
    } else {
      canvas.drawLine(Offset(-6, -size.height * 0.1), Offset(-18 * direction.sign, 2), leg);
      canvas.drawLine(Offset(6, -size.height * 0.08), Offset(14 * direction.sign, 4), leg);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoalkeeperPainter old) =>
      old.dive != dive || old.direction != direction;
}

/// كرة مع ظل ودوران بسيط.
class PenaltyBallSprite extends StatelessWidget {
  const PenaltyBallSprite({
    super.key,
    required this.palette,
    required this.size,
    this.spin = 0,
  });

  final PenaltyPalette palette;
  final double size;
  final double spin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + 10,
      child: CustomPaint(
        painter: _BallPainter(palette: palette, ballSize: size, spin: spin),
      ),
    );
  }
}

class _BallPainter extends CustomPainter {
  _BallPainter({required this.palette, required this.ballSize, required this.spin});

  final PenaltyPalette palette;
  final double ballSize;
  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.45;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + ballSize * 0.55), width: ballSize * 0.9, height: ballSize * 0.28),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(spin);

    canvas.drawCircle(Offset.zero, ballSize * 0.5, Paint()..color = palette.ballFill);
    canvas.drawCircle(Offset.zero, ballSize * 0.5, Paint()
      ..color = palette.ballBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    final patch = Paint()..color = palette.ballIcon.withValues(alpha: 0.85);
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 + spin;
      canvas.drawCircle(Offset(math.cos(a) * ballSize * 0.22, math.sin(a) * ballSize * 0.22), ballSize * 0.11, patch);
    }
  }

  @override
  bool shouldRepaint(covariant _BallPainter old) => old.spin != spin || old.ballSize != ballSize;
}

/// خطوط منطقة الجزاء بمنظور بسيط.
class PenaltyPitchMarkings extends StatelessWidget {
  const PenaltyPitchMarkings({super.key, required this.palette});

  final PenaltyPalette palette;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PitchMarkingsPainter(palette: palette),
      size: Size.infinite,
    );
  }
}

class _PitchMarkingsPainter extends CustomPainter {
  _PitchMarkingsPainter({required this.palette});

  final PenaltyPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final goalW = size.width * 0.92;
    final goalLeft = (size.width - goalW) / 2;
    final goalTop = size.height * 0.08;
    final goalH = size.height * 0.55;

    // خط منطقة الجزاء
    final boxTop = goalTop + goalH;
    final boxBottom = size.height * 0.82;
    final boxInset = goalW * 0.08;
    final box = Path()
      ..moveTo(goalLeft + boxInset, boxTop)
      ..lineTo(goalLeft + boxInset, boxBottom)
      ..lineTo(goalLeft + goalW - boxInset, boxBottom)
      ..lineTo(goalLeft + goalW - boxInset, boxTop);
    canvas.drawPath(box, line);

    // نقطة الجزاء
    final spotY = size.height * 0.76;
    final spotX = size.width * 0.5;
    canvas.drawCircle(Offset(spotX, spotY), 5, Paint()..color = Colors.white.withValues(alpha: 0.55));
    canvas.drawCircle(Offset(spotX, spotY), 5, line..strokeWidth = 1.5);

    // خطوط عشب
    final stripe = Paint()..color = Colors.black.withValues(alpha: 0.04);
    for (var y = goalTop; y < size.height; y += 18) {
      if ((y ~/ 18).isEven) {
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, 9), stripe);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PitchMarkingsPainter old) => false;
}

/// يحوّل زاوية المرمى إلى اتجاه انقضاض الحارس (-1..1).
double keeperDiveDirection(GoalZone zone) {
  return switch (zone) {
    GoalZone.leftBottom || GoalZone.leftTop => -1.0,
    GoalZone.rightBottom || GoalZone.rightTop => 1.0,
    GoalZone.center => 0.0,
  };
}