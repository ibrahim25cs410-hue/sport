import 'package:flutter/material.dart';

import 'penalty_launcher.dart';

/// جسر للروابط العميقة — يفتح اللعبة كـ overlay ثم يغلق المسار.
class PenaltyMenuScreen extends StatefulWidget {
  const PenaltyMenuScreen({super.key});

  @override
  State<PenaltyMenuScreen> createState() => _PenaltyMenuScreenState();
}

class _PenaltyMenuScreenState extends State<PenaltyMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await openPenaltyGame(context);
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
