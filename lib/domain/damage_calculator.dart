import 'dart:math';

import '../data/models/skill.dart' show SkillElement;

class DamageResult {
  final int damage;
  final bool isCritical;
  final bool isMiss;
  final double elementalMultiplier;

  const DamageResult({
    required this.damage,
    this.isCritical = false,
    this.isMiss = false,
    this.elementalMultiplier = 1.0,
  });
}

class DamageCalculator {
  final Random _random;

  DamageCalculator({Random? random}) : _random = random ?? Random();

  double _elementalMultiplier(
    SkillElement skillElement,
    List<SkillElement> targetWeaknesses,
    List<SkillElement> targetResistances,
  ) {
    if (skillElement == SkillElement.none) return 1.0;
    if (targetWeaknesses.contains(skillElement)) return 1.5;
    if (targetResistances.contains(skillElement)) return 0.5;
    return 1.0;
  }

  DamageResult calculatePhysicalDamage({
    required int attackStat,
    required int defenseStat,
    required int skillPower,
    double accuracy = 1.0,
    bool isDefending = false,
    SkillElement skillElement = SkillElement.none,
    List<SkillElement> targetWeaknesses = const [],
    List<SkillElement> targetResistances = const [],
  }) {
    // Check miss
    if (_random.nextDouble() > accuracy) {
      return const DamageResult(damage: 0, isMiss: true);
    }

    final effectiveDefense =
        isDefending ? (defenseStat * 1.5).round() : defenseStat;
    final baseDamage =
        (attackStat * skillPower) / effectiveDefense.clamp(1, 9999);
    final variance = 0.9 + _random.nextDouble() * 0.2; // 90%-110%
    final isCritical = _random.nextDouble() < 0.08; // 8% crit rate
    final critMultiplier = isCritical ? 1.5 : 1.0;
    final elemMult = _elementalMultiplier(
        skillElement, targetWeaknesses, targetResistances);

    final finalDamage =
        (baseDamage * variance * critMultiplier * elemMult).round().clamp(1, 9999);

    return DamageResult(
      damage: finalDamage,
      isCritical: isCritical,
      elementalMultiplier: elemMult,
    );
  }

  DamageResult calculateMagicalDamage({
    required int magicAttackStat,
    required int magicDefenseStat,
    required int skillPower,
    bool isDefending = false,
    SkillElement skillElement = SkillElement.none,
    List<SkillElement> targetWeaknesses = const [],
    List<SkillElement> targetResistances = const [],
  }) {
    final effectiveMDef =
        isDefending ? (magicDefenseStat * 1.5).round() : magicDefenseStat;
    final baseDamage =
        (magicAttackStat * skillPower) / effectiveMDef.clamp(1, 9999);
    final variance = 0.95 + _random.nextDouble() * 0.1; // 95%-105%
    final elemMult = _elementalMultiplier(
        skillElement, targetWeaknesses, targetResistances);

    final finalDamage = (baseDamage * variance * elemMult).round().clamp(1, 9999);

    return DamageResult(damage: finalDamage, elementalMultiplier: elemMult);
  }

  int calculateHealing({
    required int magicAttackStat,
    required int skillPower,
  }) {
    final baseHeal = magicAttackStat * skillPower * 0.5;
    final variance = 0.95 + _random.nextDouble() * 0.1;
    return (baseHeal * variance).round().clamp(1, 9999);
  }

  int calculateItemHealing({required int power}) {
    return power;
  }

  bool calculateFleeChance({
    required int partyAverageSpeed,
    required int enemyAverageSpeed,
    bool isBoss = false,
  }) {
    if (isBoss) return false;
    final speedDiff = partyAverageSpeed - enemyAverageSpeed;
    final chance = 0.5 + (speedDiff * 0.05);
    return _random.nextDouble() < chance.clamp(0.1, 0.9);
  }

  /// Basic attack damage (no skill, power = 10)
  DamageResult calculateBasicAttack({
    required int attackStat,
    required int defenseStat,
    bool isDefending = false,
  }) {
    return calculatePhysicalDamage(
      attackStat: attackStat,
      defenseStat: defenseStat,
      skillPower: 10,
      isDefending: isDefending,
    );
  }
}
