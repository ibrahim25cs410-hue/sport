import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../utils/l10n_extension.dart';
import '../../widgets/common.dart';
import '../../widgets/premium/glass_surface.dart';
import 'game_logic.dart';
import 'penalty_sfx.dart';
import 'penalty_sprites.dart';
import 'penalty_theme.dart';

/// واجهة لعبة ركلات الجزاء — مرمى، كرة، وحارس.
class PenaltyShootoutGameView extends StatefulWidget {
  const PenaltyShootoutGameView({
    super.key,
    required this.mode,
    this.embedded = false,
    this.onExit,
  });

  final PenaltyGameMode mode;
  final bool embedded;
  final VoidCallback? onExit;

  @override
  State<PenaltyShootoutGameView> createState() => _PenaltyShootoutGameViewState();
}

class _PenaltyShootoutGameViewState extends State<PenaltyShootoutGameView> with SingleTickerProviderStateMixin {
  late final PenaltyGameLogic _logic;
  late final AnimationController _shakeCtrl;
  GoalZone? _animShot;
  GoalZone? _animKeeper;
  bool _showPassPhone = false;
  int _kickAnimKey = 0;
  int _roleSwitchKey = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _logic = PenaltyGameLogic(mode: widget.mode)..addListener(_onLogicChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _logic.startRound());
  }

  @override
  void dispose() {
    _logic.removeListener(_onLogicChanged);
    _logic.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onLogicChanged() {
    if (_logic.phase == GamePhase.resolving) {
      _animShot = _logic.shotZone;
      _animKeeper = _logic.keeperZone;
      _kickAnimKey++;
      unawaited(PenaltySfx.playKick());
    }
    if (_logic.phase == GamePhase.keeperAiming &&
        widget.mode == PenaltyGameMode.twoPlayers &&
        _logic.shotZone != null) {
      setState(() {
        _showPassPhone = true;
        _roleSwitchKey++;
      });
      Future<void>.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _showPassPhone = false);
      });
    }
    if (_logic.phase == GamePhase.shooterAiming && widget.mode == PenaltyGameMode.twoPlayers) {
      _roleSwitchKey++;
    }
    setState(() {});
  }

  Future<void> _finishResolution() async {
    if (_logic.phase != GamePhase.resolving) return;
    _logic.completeResolution();
    final result = _logic.lastResult;
    if (result == ShotResult.post) {
      await _shakeCtrl.forward(from: 0);
      if (mounted) await _shakeCtrl.reverse();
    }
    if (result == ShotResult.goal) {
      await PenaltySfx.playGoal();
    } else if (result == ShotResult.saved) {
      await PenaltySfx.playSave();
    } else if (result == ShotResult.post) {
      await PenaltySfx.playPost();
    }
  }

  void _exit() {
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      Navigator.of(context).pop();
    }
  }

  bool get _canShooterTap =>
      _logic.phase == GamePhase.shooterAiming && !(widget.mode == PenaltyGameMode.vsAi && _logic.isAiShooter);

  bool get _canKeeperControl =>
      _logic.phase == GamePhase.keeperAiming && !(widget.mode == PenaltyGameMode.vsAi && _logic.isAiKeeper);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = PenaltyPalette(context);

    final body = AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        final shake = sin(_shakeCtrl.value * pi * 7) * 9 * (1 - _shakeCtrl.value);
        return Transform.translate(offset: Offset(shake, shake * 0.35), child: child);
      },
      child: Stack(
        children: [
          Column(
            children: [
              _ScoreBoard(logic: _logic, l10n: l10n, palette: palette),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
                        child: _GoalPitch(
                          logic: _logic,
                          palette: palette,
                          kickAnimKey: _kickAnimKey,
                          animShot: _animShot,
                          animKeeper: _animKeeper,
                          canShooterTap: _canShooterTap,
                          onShotZone: _logic.selectShotZone,
                          onKickComplete: _finishResolution,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PhaseBanner(
                            key: ValueKey('phase-$_roleSwitchKey-${_logic.phase}-${_logic.shooter}'),
                            logic: _logic,
                            l10n: l10n,
                            palette: palette,
                          ),
                          if (_canKeeperControl) _KeeperControls(palette: palette, onPick: _logic.selectKeeperZone),
                          const SizedBox(height: DesignTokens.spaceMd),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showPassPhone) _PassPhoneOverlay(message: l10n.penaltyPassPhone, palette: palette),
          if (_logic.phase == GamePhase.roundSummary)
            _RoundSummaryOverlay(
              logic: _logic,
              l10n: l10n,
              palette: palette,
              onContinue: _logic.advanceAfterSummary,
            ),
          if (_logic.phase == GamePhase.finished)
            _GameOverOverlay(
              logic: _logic,
              l10n: l10n,
              palette: palette,
              onReplay: () => _logic..reset()..startRound(),
              onExit: _exit,
            ),
        ],
      ),
    );

    if (widget.embedded) {
      return GlassSurface(
        borderRadius: DesignTokens.radius2xl,
        blur: 12,
        child: Column(
          children: [
            if (_logic.aiDifficultyLevel > 0 && widget.mode == PenaltyGameMode.vsAi)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                child: Chip(
                  label: Text(l10n.penaltyAiLevel(_logic.aiDifficultyLevel)),
                  backgroundColor: palette.accent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return RtlScaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        title: Text(l10n.penaltyShootout),
        actions: [
          if (_logic.aiDifficultyLevel > 0 && widget.mode == PenaltyGameMode.vsAi)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceMd),
              child: Center(
                child: Chip(
                  label: Text(l10n.penaltyAiLevel(_logic.aiDifficultyLevel)),
                  backgroundColor: palette.accent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({required this.logic, required this.l10n, required this.palette});

  final PenaltyGameLogic logic;
  final dynamic l10n;
  final PenaltyPalette palette;

  @override
  Widget build(BuildContext context) {
    final p1 = logic.mode == PenaltyGameMode.vsAi ? l10n.penaltyYou : l10n.penaltyPlayer1;
    final p2 = logic.mode == PenaltyGameMode.vsAi ? l10n.penaltyRobot : l10n.penaltyPlayer2;

    return Container(
      margin: const EdgeInsets.all(DesignTokens.spaceMd),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd, horizontal: DesignTokens.spaceXl),
      decoration: BoxDecoration(
        color: palette.scoreBoardBg,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: palette.scoreBoardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreColumn(name: p1, score: logic.player1Score, active: logic.shooter == 1, palette: palette),
          Column(
            children: [
              Text(
                logic.suddenDeath ? l10n.penaltySuddenDeath : l10n.penaltyRound(logic.roundIndex + 1),
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Icon(Icons.sports_soccer_rounded, color: palette.accent, size: 22),
            ],
          ),
          _ScoreColumn(name: p2, score: logic.player2Score, active: logic.shooter == 2, palette: palette),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({required this.name, required this.score, required this.active, required this.palette});

  final String name;
  final int score;
  final bool active;
  final PenaltyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: active ? palette.accent : palette.textMuted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(color: palette.textPrimary, fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _GoalPitch extends StatelessWidget {
  const _GoalPitch({
    required this.logic,
    required this.palette,
    required this.kickAnimKey,
    required this.animShot,
    required this.animKeeper,
    required this.canShooterTap,
    required this.onShotZone,
    required this.onKickComplete,
  });

  final PenaltyGameLogic logic;
  final PenaltyPalette palette;
  final int kickAnimKey;
  final GoalZone? animShot;
  final GoalZone? animKeeper;
  final bool canShooterTap;
  final ValueChanged<GoalZone> onShotZone;
  final Future<void> Function() onKickComplete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final goalW = w * 0.92;
        final goalH = h * 0.55;
        final goalLeft = (w - goalW) / 2;
        final goalTop = h * 0.08;
        final spotX = w * 0.5;
        final spotY = h * 0.76;
        final animMs = 540 - logic.aiDifficultyLevel * 45;
        final keeperLineY = goalTop + goalH - 6;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.pitchTop, palette.pitchBottom],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                ),
              ),
            ),
            Positioned.fill(child: PenaltyPitchMarkings(palette: palette)),
            Positioned(
              left: goalLeft,
              top: goalTop,
              width: goalW,
              height: goalH,
              child: _GoalFrame(
                palette: palette,
                canTap: canShooterTap,
                onZoneTap: onShotZone,
                highlightedShot: logic.phase == GamePhase.shooterAiming ? null : animShot,
              ),
            ),
            if (logic.phase == GamePhase.resolving && animShot != null)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(kickAnimKey),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: animMs),
                  curve: Curves.easeInCubic,
                  onEnd: onKickComplete,
                  builder: (context, t, _) {
                    final start = Offset(spotX, spotY);
                    final end = _zoneOffset(animShot!, goalLeft, goalTop, goalW, goalH);
                    final pos = penaltyArcOffset(start, end, t);
                    final keeperT = ((t - 0.08) / 0.92).clamp(0.0, 1.0);
                    final keeperX = goalLeft + goalW * _keeperRelX(animKeeper ?? GoalZone.center, keeperT);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: spotX - 28,
                          top: spotY + 8,
                          child: PenaltyPlayerSprite(palette: palette, kickProgress: (t * 2.2).clamp(0.0, 1.0)),
                        ),
                        Positioned(
                          left: pos.dx - 16,
                          top: pos.dy - 16,
                          child: PenaltyBallSprite(palette: palette, size: 28, spin: t * 12),
                        ),
                        if (animKeeper != null)
                          Positioned(
                            left: keeperX - 26,
                            top: keeperLineY - 58,
                            child: PenaltyGoalkeeperSprite(
                              palette: palette,
                              diveProgress: keeperT,
                              diveDirection: keeperDiveDirection(animKeeper!),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              )
            else ...[
              Positioned(
                left: spotX - 28,
                top: spotY + 8,
                child: PenaltyPlayerSprite(
                  palette: palette,
                  kickProgress: logic.phase == GamePhase.shooterAiming ? 0 : 0,
                ),
              ),
              Positioned(
                left: spotX - 16,
                top: spotY - 16,
                child: PenaltyBallSprite(palette: palette, size: 28),
              ),
              Positioned(
                left: goalLeft + goalW * 0.5 - 26,
                top: keeperLineY - 58,
                child: PenaltyGoalkeeperSprite(
                  palette: palette,
                  diveProgress: 0,
                  diveDirection: animKeeper != null ? keeperDiveDirection(animKeeper!) : 0,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static double _keeperRelX(GoalZone zone, double progress) {
    final target = switch (zone) {
      GoalZone.leftBottom || GoalZone.leftTop => 0.18,
      GoalZone.center => 0.5,
      GoalZone.rightBottom || GoalZone.rightTop => 0.82,
    };
    return 0.5 + (target - 0.5) * progress;
  }

  static Offset _zoneOffset(GoalZone zone, double left, double top, double w, double h) {
    final rel = switch (zone) {
      GoalZone.leftBottom => const Offset(0.18, 0.82),
      GoalZone.leftTop => const Offset(0.18, 0.22),
      GoalZone.center => const Offset(0.5, 0.52),
      GoalZone.rightTop => const Offset(0.82, 0.22),
      GoalZone.rightBottom => const Offset(0.82, 0.82),
    };
    return Offset(left + w * rel.dx, top + h * rel.dy);
  }
}

class _GoalFrame extends StatelessWidget {
  const _GoalFrame({
    required this.palette,
    required this.canTap,
    required this.onZoneTap,
    this.highlightedShot,
  });

  final PenaltyPalette palette;
  final bool canTap;
  final ValueChanged<GoalZone> onZoneTap;
  final GoalZone? highlightedShot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return CustomPaint(
          size: Size(w, h),
          painter: _GoalPainter(palette: palette),
          child: Stack(
            children: GoalZone.values.map((zone) {
              final rect = _zoneRect(zone, w, h);
              final selected = highlightedShot == zone;
              return Positioned.fromRect(
                rect: rect,
                child: GestureDetector(
                  onTap: canTap ? () => onZoneTap(zone) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: selected
                          ? palette.zoneHighlight
                          : canTap
                              ? palette.zoneTap
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      border: canTap ? Border.all(color: palette.goalPost.withValues(alpha: 0.12)) : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Rect _zoneRect(GoalZone zone, double w, double h) {
    const pad = 8.0;
    final cellW = (w - pad * 2) / 3;
    final cellH = (h - pad * 2) / 2;
    return switch (zone) {
      GoalZone.leftTop => Rect.fromLTWH(pad, pad, cellW - 4, cellH - 4),
      GoalZone.center => Rect.fromLTWH(pad + cellW, pad + cellH * 0.15, cellW - 4, cellH * 1.2),
      GoalZone.rightTop => Rect.fromLTWH(pad + cellW * 2, pad, cellW - 4, cellH - 4),
      GoalZone.leftBottom => Rect.fromLTWH(pad, pad + cellH, cellW - 4, cellH - 4),
      GoalZone.rightBottom => Rect.fromLTWH(pad + cellW * 2, pad + cellH, cellW - 4, cellH - 4),
    };
  }
}

class _GoalPainter extends CustomPainter {
  _GoalPainter({required this.palette});

  final PenaltyPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final post = Paint()
      ..color = palette.goalPost
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final net = Paint()
      ..color = palette.goalNet
      ..strokeWidth = 1;

    final r = RRect.fromRectAndRadius(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4), const Radius.circular(8));
    canvas.drawRRect(r, post);

    for (var x = 12.0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), net);
    }
    for (var y = 12.0; y < size.height; y += 14) {
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), net);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalPainter oldDelegate) => oldDelegate.palette != palette;
}

class _KeeperControls extends StatelessWidget {
  const _KeeperControls({required this.palette, required this.onPick});

  final PenaltyPalette palette;
  final ValueChanged<GoalZone> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.penaltyYourTurnSave,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Row(
            children: [
              _DiveButton(zone: GoalZone.leftTop, icon: Icons.north_west, palette: palette, onPick: onPick),
              _DiveButton(zone: GoalZone.leftBottom, icon: Icons.south_west, palette: palette, onPick: onPick),
              _DiveButton(zone: GoalZone.center, icon: Icons.arrow_upward, palette: palette, onPick: onPick),
              _DiveButton(zone: GoalZone.rightTop, icon: Icons.north_east, palette: palette, onPick: onPick),
              _DiveButton(zone: GoalZone.rightBottom, icon: Icons.south_east, palette: palette, onPick: onPick),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiveButton extends StatelessWidget {
  const _DiveButton({required this.zone, required this.icon, required this.palette, required this.onPick});

  final GoalZone zone;
  final IconData icon;
  final PenaltyPalette palette;
  final ValueChanged<GoalZone> onPick;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: palette.pitchBottom.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: InkWell(
            onTap: () => onPick(zone),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: SizedBox(
              height: 52,
              child: Icon(icon, color: palette.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseBanner extends StatelessWidget {
  const _PhaseBanner({super.key, required this.logic, required this.l10n, required this.palette});

  final PenaltyGameLogic logic;
  final dynamic l10n;
  final PenaltyPalette palette;

  @override
  Widget build(BuildContext context) {
    String text;
    if (logic.phase == GamePhase.shooterAiming) {
      text = l10n.penaltyYourTurnShoot(logic.shooterLabel(
        player1: l10n.penaltyPlayer1,
        player2: l10n.penaltyPlayer2,
        robot: l10n.penaltyRobot,
      ));
    } else if (logic.phase == GamePhase.keeperAiming) {
      text = logic.isAiKeeper
          ? l10n.penaltyAiSaving
          : l10n.penaltyKeeperTurn(logic.keeperLabel(
              player1: l10n.penaltyPlayer1,
              player2: l10n.penaltyPlayer2,
              robot: l10n.penaltyRobot,
            ));
    } else if (logic.phase == GamePhase.resolving) {
      text = l10n.loading;
    } else {
      return const SizedBox(height: DesignTokens.spaceMd);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: Padding(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceSm),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PassPhoneOverlay extends StatelessWidget {
  const _PassPhoneOverlay({required this.message, required this.palette});

  final String message;
  final PenaltyPalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 320),
      child: Container(
        color: palette.overlayScrim,
        alignment: Alignment.center,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.all(DesignTokens.space2xl),
            padding: const EdgeInsets.all(DesignTokens.spaceXl),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [palette.pitchBottom, palette.accent.withValues(alpha: 0.85)]),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phonelink_ring_rounded, color: palette.textPrimary, size: 48),
                const SizedBox(height: DesignTokens.spaceMd),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundSummaryOverlay extends StatelessWidget {
  const _RoundSummaryOverlay({
    required this.logic,
    required this.l10n,
    required this.palette,
    required this.onContinue,
  });

  final PenaltyGameLogic logic;
  final dynamic l10n;
  final PenaltyPalette palette;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final text = switch (logic.lastResult) {
      ShotResult.goal => l10n.penaltyGoal,
      ShotResult.saved => l10n.penaltySaved,
      ShotResult.post => l10n.penaltyPost,
      null => '',
    };

    return GestureDetector(
      onTap: onContinue,
      child: Container(
        color: palette.overlayScrim.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2xl, vertical: DesignTokens.spaceXl),
          decoration: BoxDecoration(
            color: palette.summaryCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: palette.accent.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                logic.lastResult == ShotResult.goal ? Icons.celebration_rounded : Icons.block_rounded,
                color: palette.accent,
                size: 40,
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              Text(text, style: TextStyle(color: palette.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(l10n.penaltyTapContinue, style: TextStyle(color: palette.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.logic,
    required this.l10n,
    required this.palette,
    required this.onReplay,
    required this.onExit,
  });

  final PenaltyGameLogic logic;
  final dynamic l10n;
  final PenaltyPalette palette;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final winner = logic.winner;
    final title = winner == null
        ? l10n.penaltyDraw
        : l10n.penaltyWinner(winner == 1
            ? (logic.mode == PenaltyGameMode.vsAi ? l10n.penaltyYou : l10n.penaltyPlayer1)
            : (logic.mode == PenaltyGameMode.vsAi ? l10n.penaltyRobot : l10n.penaltyPlayer2));

    return Container(
      color: palette.overlayScrim,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(DesignTokens.space2xl),
        padding: const EdgeInsets.all(DesignTokens.spaceXl),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [palette.pitchBottom, palette.accent]),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.penaltyGameOver, style: TextStyle(color: palette.textMuted, fontSize: 14)),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: DesignTokens.spaceLg),
            Text(
              '${logic.player1Score} - ${logic.player2Score}',
              style: TextStyle(color: palette.accent, fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: DesignTokens.spaceXl),
            FilledButton(
              onPressed: onReplay,
              child: Text(l10n.penaltyPlayAgain),
            ),
            TextButton(
              onPressed: onExit,
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
