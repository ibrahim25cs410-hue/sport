import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';
import '../../utils/l10n_extension.dart';
import '../../widgets/premium/glass_surface.dart';
import 'game_logic.dart';

/// لوحة اختيار نمط اللعب داخل الـ overlay.
class PenaltyMenuPanel extends StatelessWidget {
  const PenaltyMenuPanel({super.key, required this.onPlay, this.onPlayFlame});

  final ValueChanged<PenaltyGameMode> onPlay;
  final VoidCallback? onPlayFlame;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;

    return GlassSurface(
      borderRadius: DesignTokens.radius2xl,
      blur: 14,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 56, color: c.primary),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              l10n.penaltyChooseMode,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceXl),
            _ModeCard(
              icon: Icons.smart_toy_rounded,
              title: l10n.penaltyVsAi,
              subtitle: l10n.penaltyVsAiHint,
              onPlay: () => onPlay(PenaltyGameMode.vsAi),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            _ModeCard(
              icon: Icons.groups_rounded,
              title: l10n.penaltyTwoPlayers,
              subtitle: l10n.penaltyTwoPlayersHint,
              onPlay: () => onPlay(PenaltyGameMode.twoPlayers),
            ),
            if (onPlayFlame != null) ...[
              const SizedBox(height: DesignTokens.spaceMd),
              _ModeCard(
                icon: Icons.videogame_asset_rounded,
                title: 'Flame Engine',
                subtitle: 'Swipe to shoot — sprite-ready beta',
                onPlay: onPlayFlame!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPlay,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.primary.withValues(alpha: 0.85), c.primaryLight.withValues(alpha: 0.65)],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            boxShadow: DesignTokens.glowShadow(c.primary, subtle: true),
          ),
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: DesignTokens.onNeon.withValues(alpha: 0.2),
                child: Icon(icon, color: DesignTokens.onNeon, size: 28),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: DesignTokens.onNeon, fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: DesignTokens.onNeon.withValues(alpha: 0.88), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: DesignTokens.onNeon, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}
