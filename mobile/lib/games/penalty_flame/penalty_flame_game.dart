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

  late Vector2 _fieldSize;
  late GoalFrame _goal;
  late PlayerShooter _player;
  late Goalkeeper _keeper;
  late PenaltyBall _ball;
  bool _built = false;
  bool _resolving = false;

  Vector2? _panStart;
  Vector2? _panCurrent;
  String _status = 'Swipe toward the goal';

  @override
  Color backgroundColor() => const Color(0xFF0B3D1C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (size.x > 0 && size.y > 0) {
      await _buildField(size);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_built && size.x > 0 && size.y > 0) {
      _buildField(size);
    }
  }

  Future<void> _buildField(Vector2 fieldSize) async {
    if (_built) return;
    _built = true;
    _fieldSize = fieldSize.clone();

    // Flame 1.16+: drawables must live on [world] (not the game root).
    final pitch = RectangleComponent(
      size: _fieldSize,
      paint: Paint()..color = const Color(0xFF1B5E20),
    );
    final stripeH = _fieldSize.y / 10;
    for (var i = 0; i < 10; i += 2) {
      pitch.add(
        RectangleComponent(
          position: Vector2(0, i * stripeH),
          size: Vector2(_fieldSize.x, stripeH),
          paint: Paint()..color = const Color(0xFF2E7D32),
        ),
      );
    }

    _goal = GoalFrame(size: Vector2(_fieldSize.x * 0.72, _fieldSize.y * 0.28))
      ..position = Vector2(_fieldSize.x * 0.14, _fieldSize.y * 0.08);
    _player = PlayerShooter(fieldSize: _fieldSize);
    _keeper = Goalkeeper(goalSize: _goal.size);
    _ball = PenaltyBall(fieldSize: _fieldSize);

    await world.addAll([pitch, _goal, _player, _keeper, _ball]);
    _keeper.position += _goal.position;

    camera.viewfinder.visibleGameSize = _fieldSize;
    camera.viewfinder.position = _fieldSize / 2;
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (!_built || _ball.inFlight) return;
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
    if (!_built) return;
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
    if (!_built || !_ball.inFlight || _ball.resolved || _resolving) return;

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
    if (_resolving) return;
    _resolving = true;
    _ball.resolved = true;
    _ball.inFlight = false;
    _status = switch (result) {
      PenaltyRoundResult.goal => 'GOAL!',
      PenaltyRoundResult.saved => 'SAVED!',
      PenaltyRoundResult.missed => 'MISS',
    };
    onRoundResolved?.call(result);

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!isMounted || !_built) return;
      _keeper.reset();
      _player.reset();
      _ball.resetToSpot();
      _status = 'Swipe toward the goal';
      _resolving = false;
    });
  }

  String get statusLabel => _status;
}
