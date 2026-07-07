import 'package:flutter/material.dart';

import 'penalty_overlay.dart' deferred as penalty;

/// نقطة دخول واحدة — تحميل كسول لكود اللعبة عند الضغط على «العب الآن».
Future<void> openPenaltyGame(BuildContext context) async {
  await penalty.loadLibrary();
  if (!context.mounted) return;
  await penalty.showPenaltyOverlay(context);
}
