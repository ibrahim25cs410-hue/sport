import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import 'penalty_flame_game.dart';

/// Hosts [PenaltyFlameGame] — pauses the loop when the route is covered or the app backgrounds.
class PenaltyFlameScreen extends StatefulWidget {
  const PenaltyFlameScreen({super.key});

  @override
  State<PenaltyFlameScreen> createState() => _PenaltyFlameScreenState();
}

class _PenaltyFlameScreenState extends State<PenaltyFlameScreen> with WidgetsBindingObserver {
  late final PenaltyFlameGame _game;
  String _hud = 'Swipe toward the goal';
  int _goals = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = PenaltyFlameGame(onRoundResolved: _onRound);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.pauseEngine();
    super.dispose();
  }

  @override
  void deactivate() {
    _game.pauseEngine();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (mounted) _game.resumeEngine();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted) _game.resumeEngine();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _game.pauseEngine();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _onRound(PenaltyRoundResult result) {
    if (!mounted) return;
    setState(() {
      _attempts++;
      if (result == PenaltyRoundResult.goal) _goals++;
      _hud = _game.statusLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Penalty Kick (Flame)'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceMd),
            child: Center(
              child: Text(
                '$_goals / $_attempts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              child: Text(
                _hud,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  child: GameWidget(
                    game: _game,
                    loadingBuilder: (context) => const ColoredBox(
                      color: Color(0xFF1B5E20),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorBuilder: (context, error) => ColoredBox(
                      color: const Color(0xFF1B5E20),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'تعذّر تشغيل اللعبة\n$error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
          ],
        ),
      ),
    );
  }
}
