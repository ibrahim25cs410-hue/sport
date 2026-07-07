import 'dart:math';

import 'package:flutter/foundation.dart';

/// نمط اللعب: ضد الروبوت أو لاعبان على نفس الجهاز.
enum PenaltyGameMode { vsAi, twoPlayers }

/// خمس مناطق في المرمى.
enum GoalZone { leftBottom, leftTop, center, rightTop, rightBottom }

/// مرحلة الجولة الحالية.
enum GamePhase {
  /// استعداد قبل الجولة.
  ready,
  /// المسدّد يختار الزاوية.
  shooterAiming,
  /// الحارس يختار اتجاه القفز.
  keeperAiming,
  /// تشغيل الأنيميشن.
  resolving,
  /// ملخص الجولة قبل الانتقال للتالية.
  roundSummary,
  /// انتهت المباراة.
  finished,
}

/// نتيجة الركلة.
enum ShotResult { goal, saved, post }

/// من يلعب دور المسدّد في الجولة الحالية (1 أو 2).
typedef PlayerId = int;

/// منطق ركلات الجزاء — محلي بالكامل بدون خادم.
class PenaltyGameLogic extends ChangeNotifier {
  PenaltyGameLogic({required this.mode, Random? random}) : _random = random ?? Random();

  final PenaltyGameMode mode;
  final Random _random;

  static const int kicksPerPlayer = 5;

  GamePhase phase = GamePhase.ready;
  int player1Score = 0;
  int player2Score = 0;
  int roundIndex = 0;
  int player1KicksTaken = 0;
  int player2KicksTaken = 0;
  bool suddenDeath = false;

  /// من يسدّد في هذه الجولة.
  PlayerId shooter = 1;

  GoalZone? shotZone;
  GoalZone? keeperZone;

  ShotResult? lastResult;
  String? statusMessage;

  /// أهداف المستخدم المتتالية (نمط الروبوت) لزيادة الصعوبة.
  int consecutivePlayerGoals = 0;
  int aiDifficultyLevel = 0;

  /// أول 3 ركلات للاعب ضد الروبوت — حارس ضعيف لإحساس النجاح السريع.
  bool get _easyKeeperPhase => isVsAi && shooter == 1 && player1KicksTaken < 3;

  int get _effectiveAiLevel {
    if (!isVsAi) return 0;
    if (_easyKeeperPhase) return 0;
    final kickRamp = player1KicksTaken >= 3 ? (player1KicksTaken - 2).clamp(0, 4) : 0;
    return max(aiDifficultyLevel, kickRamp);
  }

  bool get isVsAi => mode == PenaltyGameMode.vsAi;
  bool get isPlayerShooter => isVsAi ? shooter == 1 : true;
  bool get isPlayerKeeper =>
      isVsAi ? shooter == 2 : true;

  bool get isAiShooter => isVsAi && shooter == 2;
  bool get isAiKeeper => isVsAi && shooter == 1;

  int get totalScheduledKicks => suddenDeath ? roundIndex + 1 : kicksPerPlayer * 2;

  bool get isGameOver => phase == GamePhase.finished;

  int? get winner {
    if (!isGameOver) return null;
    if (player1Score > player2Score) return 1;
    if (player2Score > player1Score) return 2;
    return null;
  }

  String shooterLabel({required String player1, required String player2, required String robot}) {
    if (isVsAi) return shooter == 1 ? player1 : robot;
    return shooter == 1 ? player1 : player2;
  }

  String keeperLabel({required String player1, required String player2, required String robot}) {
    final keeper = shooter == 1 ? 2 : 1;
    if (isVsAi) return keeper == 1 ? player1 : robot;
    return keeper == 1 ? player1 : player2;
  }

  /// يبدأ الجولة التالية.
  void startRound() {
    if (phase == GamePhase.finished) return;

    shotZone = null;
    keeperZone = null;
    lastResult = null;
    shooter = _shooterForRound(roundIndex);
    phase = GamePhase.shooterAiming;
    statusMessage = null;
    notifyListeners();

    if (isAiShooter) {
      _scheduleAiShot();
    }
  }

  /// المسدّد يحدد زاوية التسديد.
  void selectShotZone(GoalZone zone) {
    if (phase != GamePhase.shooterAiming) return;
    if (isAiShooter) return;

    shotZone = zone;
    phase = GamePhase.keeperAiming;
    notifyListeners();

    if (isAiKeeper) {
      _scheduleAiSave();
    }
  }

  /// الحارس يحدد اتجاه القفز.
  void selectKeeperZone(GoalZone zone) {
    if (phase != GamePhase.keeperAiming) return;
    if (isAiKeeper) return;

    keeperZone = zone;
    _resolveShot();
  }

  void _scheduleAiShot() {
    phase = GamePhase.shooterAiming;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (phase != GamePhase.shooterAiming || !isAiShooter) return;
      shotZone = _pickAiShotZone();
      phase = GamePhase.keeperAiming;
      notifyListeners();
    });
  }

  void _scheduleAiSave() {
    final level = _effectiveAiLevel;
    final delayMs = _easyKeeperPhase ? 1150 : (950 - level * 130).clamp(320, 950);
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (phase != GamePhase.keeperAiming || !isAiKeeper) return;
      keeperZone = _pickAiKeeperZone(shotZone!);
      _resolveShot();
    });
  }

  GoalZone _pickAiShotZone() {
    const weights = <GoalZone, int>{
      GoalZone.leftBottom: 22,
      GoalZone.leftTop: 18,
      GoalZone.center: 12,
      GoalZone.rightTop: 18,
      GoalZone.rightBottom: 22,
    };
    return _weightedZone(weights);
  }

  GoalZone _pickAiKeeperZone(GoalZone incoming) {
    if (_easyKeeperPhase) {
      if (_random.nextDouble() < 0.06) return incoming;
      final neighbors = _adjacentZones(incoming);
      if (_random.nextDouble() < 0.12) return neighbors[_random.nextInt(neighbors.length)];
      return GoalZone.values[_random.nextInt(GoalZone.values.length)];
    }

    final level = _effectiveAiLevel;
    if (_random.nextDouble() < 0.16 + level * 0.09) {
      return incoming;
    }
    final neighbors = _adjacentZones(incoming);
    if (_random.nextDouble() < 0.32 + level * 0.06) {
      return neighbors[_random.nextInt(neighbors.length)];
    }
    return GoalZone.values[_random.nextInt(GoalZone.values.length)];
  }

  GoalZone _weightedZone(Map<GoalZone, int> weights) {
    final total = weights.values.fold(0, (a, b) => a + b);
    var roll = _random.nextInt(total);
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return GoalZone.center;
  }

  List<GoalZone> _adjacentZones(GoalZone zone) {
    return switch (zone) {
      GoalZone.leftBottom => [GoalZone.leftTop, GoalZone.center],
      GoalZone.leftTop => [GoalZone.leftBottom, GoalZone.center],
      GoalZone.center => [GoalZone.leftTop, GoalZone.leftBottom, GoalZone.rightTop, GoalZone.rightBottom],
      GoalZone.rightTop => [GoalZone.rightBottom, GoalZone.center],
      GoalZone.rightBottom => [GoalZone.rightTop, GoalZone.center],
    };
  }

  void _resolveShot() {
    if (shotZone == null || keeperZone == null) return;

    phase = GamePhase.resolving;
    notifyListeners();
  }

  /// للاختبارات فقط — يحاكي ركلة بزوايا محددة.
  @visibleForTesting
  void resolveForTest({required GoalZone shot, required GoalZone keeper}) {
    shotZone = shot;
    keeperZone = keeper;
    _resolveShot();
    completeResolution();
  }

  /// يُستدعى بعد انتهاء أنيميشن الكرة.
  void completeResolution() {
    if (shotZone == null || keeperZone == null) return;

    if (shotZone == keeperZone) {
      lastResult = ShotResult.saved;
    } else if (shotZone == GoalZone.center && _random.nextDouble() < 0.06) {
      lastResult = ShotResult.post;
    } else {
      lastResult = ShotResult.goal;
    }

    if (lastResult == ShotResult.goal) {
      if (shooter == 1) {
        player1Score++;
      } else {
        player2Score++;
      }
    }

    if (isVsAi && shooter == 1 && lastResult == ShotResult.goal) {
      consecutivePlayerGoals++;
      aiDifficultyLevel = max(aiDifficultyLevel, (consecutivePlayerGoals - 2).clamp(0, 4));
    } else if (isVsAi && shooter == 1) {
      consecutivePlayerGoals = 0;
    }

    if (shooter == 1) {
      player1KicksTaken++;
    } else {
      player2KicksTaken++;
    }

    if (isVsAi && player1KicksTaken > 3) {
      aiDifficultyLevel = max(aiDifficultyLevel, (player1KicksTaken - 2).clamp(0, 4));
    }

    phase = GamePhase.roundSummary;
    notifyListeners();
  }

  void advanceAfterSummary() {
    if (phase != GamePhase.roundSummary) return;

    roundIndex++;

    if (!suddenDeath &&
        player1KicksTaken >= kicksPerPlayer &&
        player2KicksTaken >= kicksPerPlayer) {
      if (player1Score == player2Score) {
        suddenDeath = true;
        startRound();
        return;
      }
      phase = GamePhase.finished;
      notifyListeners();
      return;
    }

    if (suddenDeath && roundIndex > kicksPerPlayer * 2 && roundIndex.isEven && player1Score != player2Score) {
      phase = GamePhase.finished;
      notifyListeners();
      return;
    }

    startRound();
  }

  void reset() {
    phase = GamePhase.ready;
    player1Score = 0;
    player2Score = 0;
    roundIndex = 0;
    player1KicksTaken = 0;
    player2KicksTaken = 0;
    suddenDeath = false;
    shooter = 1;
    shotZone = null;
    keeperZone = null;
    lastResult = null;
    statusMessage = null;
    consecutivePlayerGoals = 0;
    aiDifficultyLevel = 0;
    notifyListeners();
  }

  PlayerId _shooterForRound(int index) => (index % 2 == 0) ? 1 : 2;
}
