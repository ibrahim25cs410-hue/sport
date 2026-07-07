import 'package:flutter/material.dart';

import 'penalty_flame_screen.dart' deferred as flame;

/// Deep-link bridge — loads Flame code then replaces itself with the game.
class PenaltyFlameBridgeScreen extends StatefulWidget {
  const PenaltyFlameBridgeScreen({super.key});

  @override
  State<PenaltyFlameBridgeScreen> createState() => _PenaltyFlameBridgeScreenState();
}

class _PenaltyFlameBridgeScreenState extends State<PenaltyFlameBridgeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    await flame.loadLibrary();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => flame.PenaltyFlameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
