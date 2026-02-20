import 'dart:math';

import '../data/models/battle_action.dart';
import '../data/models/character.dart';
import '../data/models/enemy.dart';

class EnemyAi {
  final Random _random;

  EnemyAi({Random? random}) : _random = random ?? Random();

  BattleAction selectAction({
    required Enemy enemy,
    required List<Character> party,
    required List<Enemy> allEnemies,
  }) {
    switch (enemy.behavior) {
      case AiBehavior.aggressive:
        return _aggressiveBehavior(enemy, party);
      case AiBehavior.defensive:
        return _defensiveBehavior(enemy, party);
      case AiBehavior.random:
        return _randomBehavior(enemy, party);
      case AiBehavior.boss:
        return _bossBehavior(enemy, party);
    }
  }

  /// Aggressive: targets hero with lowest HP, uses skills when available.
  BattleAction _aggressiveBehavior(Enemy enemy, List<Character> party) {
    final aliveHeroes = party.where((h) => h.isAlive).toList();
    if (aliveHeroes.isEmpty) {
      return _basicAttack(enemy, party.first.id);
    }

    final target = aliveHeroes.reduce(
      (a, b) => a.currentHp < b.currentHp ? a : b,
    );

    // 60% chance to use a skill if available
    if (enemy.skillIds.isNotEmpty && _random.nextDouble() < 0.6) {
      final skillId = enemy.skillIds[_random.nextInt(enemy.skillIds.length)];
      return BattleAction(
        actorId: enemy.id,
        isHero: false,
        actionType: ActionType.skill,
        skillId: skillId,
        targetId: target.id,
      );
    }

    return _basicAttack(enemy, target.id);
  }

  /// Defensive: defends when HP < 30%, otherwise attacks randomly.
  BattleAction _defensiveBehavior(Enemy enemy, List<Character> party) {
    if (enemy.hpPercent < 0.3 && _random.nextBool()) {
      return BattleAction(
        actorId: enemy.id,
        isHero: false,
        actionType: ActionType.defend,
      );
    }
    return _randomBehavior(enemy, party);
  }

  /// Random: picks a random alive hero and uses basic attack.
  BattleAction _randomBehavior(Enemy enemy, List<Character> party) {
    final aliveHeroes = party.where((h) => h.isAlive).toList();
    if (aliveHeroes.isEmpty) {
      return _basicAttack(enemy, party.first.id);
    }
    final target = aliveHeroes[_random.nextInt(aliveHeroes.length)];
    return _basicAttack(enemy, target.id);
  }

  /// Boss: uses AoE below 50% HP, targets healer first.
  BattleAction _bossBehavior(Enemy enemy, List<Character> party) {
    final aliveHeroes = party.where((h) => h.isAlive).toList();
    if (aliveHeroes.isEmpty) {
      return _basicAttack(enemy, party.first.id);
    }

    // Below 50% HP and has AoE skill: use it
    if (enemy.hpPercent < 0.5 && enemy.skillIds.length > 1) {
      return BattleAction(
        actorId: enemy.id,
        isHero: false,
        actionType: ActionType.skill,
        skillId: enemy.skillIds.last, // Convention: last skill is AoE
        targetAll: true,
      );
    }

    // Use single-target skill on healer if possible
    if (enemy.skillIds.isNotEmpty) {
      final healer = aliveHeroes
          .where((h) => h.heroClass == HeroClass.healer)
          .firstOrNull;
      final target = healer ?? aliveHeroes.first;

      return BattleAction(
        actorId: enemy.id,
        isHero: false,
        actionType: ActionType.skill,
        skillId: enemy.skillIds.first,
        targetId: target.id,
      );
    }

    return _basicAttack(enemy, aliveHeroes.first.id);
  }

  BattleAction _basicAttack(Enemy enemy, String targetId) {
    return BattleAction(
      actorId: enemy.id,
      isHero: false,
      actionType: ActionType.attack,
      targetId: targetId,
    );
  }
}
