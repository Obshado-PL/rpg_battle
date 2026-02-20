import 'dart:math';

class DamageResult {
  final int damage;
  final bool isCritical;
  final bool isMiss;

  const DamageResult({
    required this.damage,
    this.isCritical = false,
    this.isMiss = false,
  });
}

class DamageCalculator {
  final Random _random;

  DamageCalculator({Random? random}) : _random = random ?? Random();

  DamageResult calculatePhysicalDamage({
    required int attackStat,
    required int defenseStat,
    required int skillPower,
    double accuracy = 1.0,
    bool isDefending = false,
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

    final finalDamage =
        (baseDamage * variance * critMultiplier).round().clamp(1, 9999);

    return DamageResult(damage: finalDamage, isCritical: isCritical);
  }

  DamageResult calculateMagicalDamage({
    required int magicAttackStat,
    required int magicDefenseStat,
    required int skillPower,
    bool isDefending = false,
  }) {
    final effectiveMDef =
        isDefending ? (magicDefenseStat * 1.5).round() : magicDefenseStat;
    final baseDamage =
        (magicAttackStat * skillPower) / effectiveMDef.clamp(1, 9999);
    final variance = 0.95 + _random.nextDouble() * 0.1; // 95%-105%

    final finalDamage = (baseDamage * variance).round().clamp(1, 9999);

    return DamageResult(damage: finalDamage);
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
