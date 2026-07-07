import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';
import '../utils/l10n_extension.dart';
import '../theme/riyada_theme_extension.dart';

/// شريط الاتصال فوق المحتوى — بدون إعادة قياس الشجرة بالكامل.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final online = context.select<ConnectivityProvider, bool>((p) => p.isOnline);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (!online)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: context.colors.error,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: context.colors.onPrimary, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.l10n.connectionLost,
                          style: TextStyle(
                            color: context.colors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
