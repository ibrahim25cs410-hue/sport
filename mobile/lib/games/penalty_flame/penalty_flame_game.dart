import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/goal_frame.dart';
import 'components/goalkeeper.dart';
import 'components/penalty_ball.dart';
import 'components/player_shooter.dart';

enum PenaltyRoundResult { goal, saved, missed }

/// Flame-powered penalty shootout — swipe up to shoot; power from swipe length.
class PenaltyFlameGame extends FlameGame with PanDetector {
  PenaltyFlameGame({this.onRoundResolved});

  final void Function(PenaltyRoundResult result)? onRoundResolved;

  late final Vector2 _fieldSize;
  late final GoalFrame _goal;
  late final PlayerShooter _player;
  late final Goalkeeper _keeper;
  late final PenaltyBall _ball;

  Vector2? _panStart;
  Vector2? _panCurrent;
  String _status = 'Swipe toward the goal';

  @override
  Color backgroundColor() => const Color(0xFF0B3D1C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _fieldSize = size;
    _goal = GoalFrame(size: Vector2(_fieldSize.x * 0.72, _fieldSize.y * 0.28))
      ..position = Vector2(_fieldSize.x * 0.14, _fieldSize.y * 0.08);
    _player = PlayerShooter(fieldSize: _fieldSize);
    _keeper = Goalkeeper(goalSize: _goal.size);
    _ball = PenaltyBall(fieldSize: _fieldSize);

    await add(RectangleComponent(
      size: _fieldSize,
      paint: Paint()..color = const Color(0xFF1B5E20),
    ));
    await add(_goal);
    await add(_player);
    _keeper.position += _goal.position;
    await add(_keeper);
    await add(_ball);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _fieldSize = size;
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (_ball.inFlight) return;
    _panStart = info.eventPosition.widget;
    _panCurrent = _panStart;
    _status = 'Release to shoot';
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    _panCurrent = info.eventPosition.widget;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    final start = _panStart;
    final end = _panCurrent;
    _panStart = null;
    _panCurrent = null;
    if (start == null || end == null || _ball.inFlight) return;

    final swipe = start - end;
    if (swipe.y < 40) {
      _status = 'Swipe upward to shoot';
      return;
    }

    final power = swipe.length.clamp(80, 320) * 2.1;
    _player.kick();
    _ball.shoot(Vector2(swipe.x, -swipe.y.abs()), power);

    final goalLeft = _goal.position.x;
    final goalWidth = _goal.size.x;
    final predictedX = ((_ball.position.x + swipe.x * 0.6) - goalLeft) / goalWidth;
    _keeper.defendAgainst(predictedX.clamp(0.0, 1.0));
    _status = '...';
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ball.inFlight || _ball.resolved) return;

    final goalRect = Rect.fromLTWH(
      _goal.position.x,
      _goal.position.y,
      _goal.size.x,
      _goal.size.y,
    );
    final ballCenter = Offset(_ball.position.x, _ball.position.y);
    final radius = _ball.size.x * 0.5;

    if (_keeper.blocks(_ball.position, radius)) {
      _resolve(PenaltyRoundResult.saved);
      return;
    }

    if (goalRect.contains(ballCenter) && _ball.position.y < _goal.position.y + _goal.size.y * 0.85) {
      _resolve(PenaltyRoundResult.goal);
      return;
    }

    if (_ball.resolved) {
      _resolve(PenaltyRoundResult.missed);
    }
  }

  void _resolve(PenaltyRoundResult result) {
    if (_ball.resolved) return;
    _ball.resolved = true;
    _ball.inFlight = false;
    _status = switch (result) {
      PenaltyRoundResult.goal => 'GOAL!',
      PenaltyRoundResult.saved => 'SAVED!',
      PenaltyRoundResult.missed => 'MISS',
    };
    onRoundResolved?.call(result);

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!isMounted) return;
      _keeper.reset();
      _player.reset();
      _ball.resetToSpot();
      _status = 'Swipe toward the goal';
    });
  }

  String get statusLabel => _status;
}
