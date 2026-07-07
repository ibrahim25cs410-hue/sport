import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';
import '../../utils/l10n_extension.dart';
import '../../widgets/premium/glass_surface.dart';
import 'game_logic.dart';
import 'game_view.dart';
import 'penalty_menu_panel.dart';
import '../penalty_flame/penalty_flame_launcher.dart';

enum _PenaltyOverlayStep { menu, game }

/// واجهة كاملة داخل Overlay زجاجي — جزء من تجربة التطبيق وليست صفحة منفصلة.
class PenaltyGameOverlay extends StatefulWidget {
  const PenaltyGameOverlay({super.key});

  @override
  State<PenaltyGameOverlay> createState() => _PenaltyGameOverlayState();
}

class _PenaltyGameOverlayState extends State<PenaltyGameOverlay> with SingleTickerProviderStateMixin {
  _PenaltyOverlayStep _step = _PenaltyOverlayStep.menu;
  PenaltyGameMode? _mode;
  late final AnimationController _enterCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fade);
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  void _close() {
    _enterCtrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _startGame(PenaltyGameMode mode) {
    setState(() {
      _mode = mode;
      _step = _PenaltyOverlayStep.game;
    });
  }

  Future<void> _startFlameGame() async {
    final navigator = Navigator.of(context);
    final host = context;
    navigator.pop();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!host.mounted) return;
    await openPenaltyFlameGame(host);
  }

  void _backToMenu() {
    setState(() {
      _mode = null;
      _step = _PenaltyOverlayStep.menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(onTap: _close, child: Container(color: c.scrimMedium)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: c.background.withValues(alpha: 0.72)),
          ),
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceMd),
                  child: Column(
                    children: [
                      _OverlayHeader(onClose: _close, onBack: _step == _PenaltyOverlayStep.game ? _backToMenu : null),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _step == _PenaltyOverlayStep.menu
                              ? PenaltyMenuPanel(
                                  key: const ValueKey('menu'),
                                  onPlay: _startGame,
                                  onPlayFlame: _startFlameGame,
                                )
                              : PenaltyShootoutGameView(
                                  key: ValueKey('game-$_mode'),
                                  mode: _mode!,
                                  embedded: true,
                                  onExit: _close,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayHeader extends StatelessWidget {
  const _OverlayHeader({required this.onClose, this.onBack});

  final VoidCallback onClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: onBack,
              color: c.onSurface,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              l10n.penaltyShootout,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          GlassSurface(
            borderRadius: DesignTokens.radiusLg,
            padding: const EdgeInsets.all(6),
            blur: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose,
              color: c.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// يعرض اللعبة كـ overlay فوق الشاشة الحالية.
Future<void> showPenaltyOverlay(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'penalty',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => const PenaltyGameOverlay(),
    transitionBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
  );
}
