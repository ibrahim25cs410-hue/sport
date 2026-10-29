import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';

/// إشعار علوي أنيق عند أحداث الحجز اللحظية (بديل Flushbar خفيف).
void showRealtimeToast(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.check_circle_rounded,
  Color? accent,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _RealtimeToast(
      title: title,
      message: message,
      icon: icon,
      accent: accent ?? DesignTokens.primaryTeal,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );

  overlay.insert(entry);
  Future<void>.delayed(const Duration(seconds: 4), () {
    if (entry.mounted) entry.remove();
  });
}

class _RealtimeToast extends StatefulWidget {
  const _RealtimeToast({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final VoidCallback onDismiss;

  @override
  State<_RealtimeToast> createState() => _RealtimeToastState();
}

class _RealtimeToastState extends State<_RealtimeToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    unawaited(_ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Positioned(
      top: top + DesignTokens.spaceMd,
      left: DesignTokens.spaceLg,
      right: DesignTokens.spaceLg,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (d) {
                if (d.primaryVelocity != null && d.primaryVelocity! < 0) _dismiss();
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surfaceElevated.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  border: Border.all(color: widget.accent.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(color: widget.accent.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8)),
                    BoxShadow(color: c.shadow.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceMd),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.accent, size: 22),
                      ),
                      const SizedBox(width: DesignTokens.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.75), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.close_rounded, size: 18, color: textColor.withValues(alpha: 0.65)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
