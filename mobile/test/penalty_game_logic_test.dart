import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/games/penalty_shootout/game_logic.dart';

void main() {
  test('goal increments shooter score when zones differ', () {
    final logic = PenaltyGameLogic(mode: PenaltyGameMode.twoPlayers, random: Random(1));
    logic.startRound();
    logic.selectShotZone(GoalZone.leftTop);
    logic.selectKeeperZone(GoalZone.rightBottom);
    logic.completeResolution();

    expect(logic.lastResult, ShotResult.goal);
    expect(logic.player1Score, 1);
  });

  test('save when keeper matches shot zone', () {
    final logic = PenaltyGameLogic(mode: PenaltyGameMode.twoPlayers, random: Random(2));
    logic.startRound();
    logic.selectShotZone(GoalZone.center);
    logic.selectKeeperZone(GoalZone.center);
    logic.completeResolution();

    expect(logic.lastResult, ShotResult.saved);
    expect(logic.player1Score, 0);
  });

  test('ai difficulty rises after three consecutive player goals', () {
    final logic = PenaltyGameLogic(mode: PenaltyGameMode.vsAi, random: Random(3));
    var playerGoals = 0;
    while (playerGoals < 3) {
      logic.startRound();
      if (logic.shooter != 1) {
        logic.resolveForTest(shot: GoalZone.center, keeper: GoalZone.center);
        logic.advanceAfterSummary();
        continue;
      }
      logic.resolveForTest(shot: GoalZone.leftBottom, keeper: GoalZone.rightTop);
      logic.advanceAfterSummary();
      playerGoals++;
    }
    expect(logic.consecutivePlayerGoals, 3);
    expect(logic.aiDifficultyLevel, greaterThan(0));
  });

  test('ai level stays low during first three player kicks', () {
    final logic = PenaltyGameLogic(mode: PenaltyGameMode.vsAi, random: Random(42));
    while (logic.player1KicksTaken < 3) {
      logic.startRound();
      if (logic.shooter == 1) {
        final saveToBreakStreak = logic.player1KicksTaken == 1;
        logic.resolveForTest(
          shot: GoalZone.leftBottom,
          keeper: saveToBreakStreak ? GoalZone.leftBottom : GoalZone.rightTop,
        );
        expect(logic.aiDifficultyLevel, 0);
        logic.advanceAfterSummary();
      } else {
        logic.resolveForTest(shot: GoalZone.center, keeper: GoalZone.center);
        logic.advanceAfterSummary();
      }
    }
    while (logic.player1KicksTaken < 4) {
      logic.startRound();
      if (logic.shooter == 1) {
        logic.resolveForTest(shot: GoalZone.leftBottom, keeper: GoalZone.rightTop);
        logic.advanceAfterSummary();
      } else {
        logic.resolveForTest(shot: GoalZone.center, keeper: GoalZone.center);
        logic.advanceAfterSummary();
      }
    }
    expect(logic.aiDifficultyLevel, greaterThan(0));
  });
}
