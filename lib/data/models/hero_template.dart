import 'character.dart';
import 'stats.dart';

enum HeroRarity { common, rare, epic }

class HeroTemplate {
  final String id;
  final String name;
  final HeroClass heroClass;
  final int spriteId;
  final HeroRarity rarity;
  final Stats baseStats;
  final List<String> startingSkillIds;
  final String? startingWeaponId;
  final String? startingArmorId;
  final String? startingAccessoryId;

  const HeroTemplate({
    required this.id,
    required this.name,
    required this.heroClass,
    required this.spriteId,
    required this.rarity,
    required this.baseStats,
    required this.startingSkillIds,
    this.startingWeaponId,
    this.startingArmorId,
    this.startingAccessoryId,
  });

  factory HeroTemplate.fromJson(Map<String, dynamic> json) {
    return HeroTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      heroClass: HeroClass.values.firstWhere(
        (e) => e.name == json['heroClass'],
      ),
      spriteId: json['spriteId'] as int,
      rarity: HeroRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => HeroRarity.common,
      ),
      baseStats: Stats.fromJson(json['baseStats'] as Map<String, dynamic>),
      startingSkillIds:
          (json['startingSkillIds'] as List<dynamic>).cast<String>(),
      startingWeaponId: json['startingWeaponId'] as String?,
      startingArmorId: json['startingArmorId'] as String?,
      startingAccessoryId: json['startingAccessoryId'] as String?,
    );
  }
}
