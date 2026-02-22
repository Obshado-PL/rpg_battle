import 'dart:math';

import '../data/models/hero_template.dart';

class GachaResult {
  final HeroTemplate hero;
  final bool isDuplicate;
  final int compensationGold;

  const GachaResult({
    required this.hero,
    required this.isDuplicate,
    this.compensationGold = 0,
  });
}

class GachaSystem {
  static const int pullCost = 300;
  static const int multiPullCost = 2700; // 10-pull discount

  // Rarity rates
  static const double _commonRate = 0.50;
  static const double _rareRate = 0.30;
  static const double _epicRate = 0.15;
  // legendary = 0.05 (remainder)

  // Duplicate compensation
  static const Map<HeroRarity, int> _compensation = {
    HeroRarity.common: 150,
    HeroRarity.rare: 300,
    HeroRarity.epic: 600,
    HeroRarity.legendary: 1200,
  };

  final Random _random;

  GachaSystem([Random? random]) : _random = random ?? Random();

  GachaResult pull({
    required Map<String, HeroTemplate> heroTemplates,
    required Set<String> ownedHeroIds,
  }) {
    // Roll rarity
    final roll = _random.nextDouble();
    final HeroRarity targetRarity;
    if (roll < _commonRate) {
      targetRarity = HeroRarity.common;
    } else if (roll < _commonRate + _rareRate) {
      targetRarity = HeroRarity.rare;
    } else if (roll < _commonRate + _rareRate + _epicRate) {
      targetRarity = HeroRarity.epic;
    } else {
      targetRarity = HeroRarity.legendary;
    }

    // Get all non-starter heroes of this rarity
    final candidates = heroTemplates.values
        .where((h) =>
            h.rarity == targetRarity &&
            !_isStarter(h.id))
        .toList();

    // Fallback: if no candidates at this rarity, use all non-starters
    final pool = candidates.isNotEmpty
        ? candidates
        : heroTemplates.values
            .where((h) => !_isStarter(h.id))
            .toList();

    if (pool.isEmpty) {
      // Edge case: return first non-starter
      final fallback = heroTemplates.values.first;
      return GachaResult(hero: fallback, isDuplicate: true, compensationGold: 150);
    }

    final selected = pool[_random.nextInt(pool.length)];
    final isDuplicate = ownedHeroIds.contains(selected.id);

    return GachaResult(
      hero: selected,
      isDuplicate: isDuplicate,
      compensationGold: isDuplicate ? _compensation[selected.rarity]! : 0,
    );
  }

  static bool _isStarter(String heroId) {
    return const {
      'hero_warrior',
      'hero_mage',
      'hero_healer',
      'hero_rogue',
    }.contains(heroId);
  }
}
