import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg_battle/data/models/character.dart';
import 'package:rpg_battle/data/models/enemy.dart';
import 'package:rpg_battle/data/models/stats.dart';
import 'package:rpg_battle/domain/damage_calculator.dart';
import 'package:rpg_battle/domain/turn_manager.dart';

void main() {
  group('DamageCalculator', () {
    late DamageCalculator calculator;

    setUp(() {
      calculator = DamageCalculator(random: Random(42));
    });

    test('calculateBasicAttack returns positive damage', () {
      final result = calculator.calculateBasicAttack(
        attackStat: 18,
        defenseStat: 10,
      );
      expect(result.damage, greaterThan(0));
      expect(result.isMiss, false);
    });

    test('defending reduces damage', () {
      final calc1 = DamageCalculator(random: Random(42));
      final normal = calc1.calculateBasicAttack(
        attackStat: 18,
        defenseStat: 10,
      );

      final calc2 = DamageCalculator(random: Random(42));
      final defended = calc2.calculateBasicAttack(
        attackStat: 18,
        defenseStat: 10,
        isDefending: true,
      );

      expect(defended.damage, lessThan(normal.damage));
    });

    test('calculateHealing returns positive value', () {
      final heal = calculator.calculateHealing(
        magicAttackStat: 14,
        skillPower: 15,
      );
      expect(heal, greaterThan(0));
    });

    test('flee chance returns false for boss', () {
      final fled = calculator.calculateFleeChance(
        partyAverageSpeed: 100,
        enemyAverageSpeed: 1,
        isBoss: true,
      );
      expect(fled, false);
    });
  });

  group('TurnManager', () {
    late TurnManager turnManager;

    setUp(() {
      turnManager = TurnManager(random: Random(42));
    });

    test('calculateTurnOrder excludes dead actors', () {
      final party = [
        Character(
          id: 'hero1',
          name: 'Hero',
          heroClass: HeroClass.warrior,
          level: 1,
          currentHp: 100,
          currentMp: 20,
          baseStats: const Stats(
            maxHp: 100, maxMp: 20, attack: 15, defense: 10,
            magicAttack: 5, magicDefense: 5, speed: 10,
          ),
          xp: 0,
          skillIds: [],
        ),
        Character(
          id: 'hero2',
          name: 'Dead Hero',
          heroClass: HeroClass.mage,
          level: 1,
          currentHp: 0, // Dead
          currentMp: 50,
          baseStats: const Stats(
            maxHp: 70, maxMp: 50, attack: 5, defense: 5,
            magicAttack: 20, magicDefense: 15, speed: 15,
          ),
          xp: 0,
          skillIds: [],
        ),
      ];

      final enemies = [
        Enemy(
          id: 'enemy1',
          name: 'Slime',
          currentHp: 40,
          stats: const Stats(
            maxHp: 40, maxMp: 0, attack: 8, defense: 4,
            magicAttack: 3, magicDefense: 4, speed: 5,
          ),
          behavior: AiBehavior.random,
          skillIds: [],
          xpReward: 10,
          goldReward: 5,
          spriteColor: '0xFF4CAF50',
        ),
      ];

      final order = turnManager.calculateTurnOrder(
        party: party,
        enemies: enemies,
      );

      expect(order, isNot(contains('hero2')));
      expect(order, contains('hero1'));
      expect(order, contains('enemy1'));
    });
  });
}
