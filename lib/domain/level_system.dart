import 'dart:math';

import '../data/models/character.dart';
import '../data/models/stats.dart';

class LevelSystem {
  /// XP required to reach the next level: 100 * level^1.5
  int xpForNextLevel(int currentLevel) {
    return (100 * pow(currentLevel, 1.5)).round();
  }

  /// Skill unlock thresholds per class.
  static const _skillUnlocks = {
    HeroClass.warrior: {3: 'warrior_cleave'},
    HeroClass.mage: {3: 'mage_lightning'},
    HeroClass.healer: {3: 'healer_group_heal'},
    HeroClass.rogue: {3: 'rogue_shadowstrike'},
  };

  /// Apply XP gain and handle level ups. Returns updated character.
  Character applyXp(Character character, int xpGained) {
    var newXp = character.xp + xpGained;
    var newLevel = character.level;
    var newStats = character.baseStats;
    var newSkills = List<String>.from(character.skillIds);
    final levelUps = <int>[];

    while (newXp >= xpForNextLevel(newLevel)) {
      newXp -= xpForNextLevel(newLevel);
      newLevel++;
      newStats = _levelUpStats(newStats, character.heroClass);
      levelUps.add(newLevel);

      // Check for skill unlocks at this level
      final unlock = _skillUnlocks[character.heroClass]?[newLevel];
      if (unlock != null && !newSkills.contains(unlock)) {
        newSkills.add(unlock);
      }
    }

    return character.copyWith(
      level: newLevel,
      xp: newXp,
      baseStats: newStats,
      skillIds: newSkills,
      // Full heal on level up
      currentHp: levelUps.isNotEmpty ? newStats.maxHp : character.currentHp,
      currentMp: levelUps.isNotEmpty ? newStats.maxMp : character.currentMp,
    );
  }

  Stats _levelUpStats(Stats current, HeroClass heroClass) {
    switch (heroClass) {
      case HeroClass.warrior:
        return current.copyWith(
          maxHp: current.maxHp + 15,
          maxMp: current.maxMp + 3,
          attack: current.attack + 4,
          defense: current.defense + 3,
          magicAttack: current.magicAttack + 1,
          magicDefense: current.magicDefense + 1,
          speed: current.speed + 1,
        );
      case HeroClass.mage:
        return current.copyWith(
          maxHp: current.maxHp + 8,
          maxMp: current.maxMp + 10,
          attack: current.attack + 1,
          defense: current.defense + 1,
          magicAttack: current.magicAttack + 5,
          magicDefense: current.magicDefense + 3,
          speed: current.speed + 2,
        );
      case HeroClass.healer:
        return current.copyWith(
          maxHp: current.maxHp + 10,
          maxMp: current.maxMp + 8,
          attack: current.attack + 1,
          defense: current.defense + 2,
          magicAttack: current.magicAttack + 3,
          magicDefense: current.magicDefense + 4,
          speed: current.speed + 2,
        );
      case HeroClass.rogue:
        return current.copyWith(
          maxHp: current.maxHp + 10,
          maxMp: current.maxMp + 4,
          attack: current.attack + 3,
          defense: current.defense + 1,
          magicAttack: current.magicAttack + 1,
          magicDefense: current.magicDefense + 1,
          speed: current.speed + 5,
        );
    }
  }
}
