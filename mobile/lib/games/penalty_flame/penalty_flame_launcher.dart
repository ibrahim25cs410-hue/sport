import 'package:flutter/material.dart';

import 'penalty_flame_screen.dart' deferred as flame;

/// Opens the Flame penalty mini-game (lazy-loaded).
Future<void> openPenaltyFlameGame(BuildContext context) async {
  await flame.loadLibrary();
  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(builder: (_) => flame.PenaltyFlameScreen()),
  );
}
