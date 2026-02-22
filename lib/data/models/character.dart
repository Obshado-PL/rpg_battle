import 'stats.dart';
import 'status_effect.dart';

enum HeroClass { warrior, mage, healer, rogue }

class Character {
  final String id;
  final String name;
  final HeroClass heroClass;
  final int spriteId;
  final int level;
  final int currentHp;
  final int currentMp;
  final Stats baseStats;
  final int xp;
  final List<String> skillIds;
  final bool isDefending;
  final String? weaponId;
  final String? armorId;
  final String? accessoryId;
  final List<StatusEffect> statusEffects;

  const Character({
    required this.id,
    required this.name,
    required this.heroClass,
    this.spriteId = 0,
    required this.level,
    required this.currentHp,
    required this.currentMp,
    required this.baseStats,
    required this.xp,
    required this.skillIds,
    this.isDefending = false,
    this.weaponId,
    this.armorId,
    this.accessoryId,
    this.statusEffects = const [],
  });

  bool get isAlive => currentHp > 0;
  double get hpPercent => currentHp / baseStats.maxHp;
  double get mpPercent => baseStats.maxMp > 0 ? currentMp / baseStats.maxMp : 0;

  static const _undefined = Object();

  Character copyWith({
    String? id,
    String? name,
    HeroClass? heroClass,
    int? spriteId,
    int? level,
    int? currentHp,
    int? currentMp,
    Stats? baseStats,
    int? xp,
    List<String>? skillIds,
    bool? isDefending,
    Object? weaponId = _undefined,
    Object? armorId = _undefined,
    Object? accessoryId = _undefined,
    List<StatusEffect>? statusEffects,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      heroClass: heroClass ?? this.heroClass,
      spriteId: spriteId ?? this.spriteId,
      level: level ?? this.level,
      currentHp: currentHp ?? this.currentHp,
      currentMp: currentMp ?? this.currentMp,
      baseStats: baseStats ?? this.baseStats,
      xp: xp ?? this.xp,
      skillIds: skillIds ?? this.skillIds,
      isDefending: isDefending ?? this.isDefending,
      weaponId: weaponId == _undefined ? this.weaponId : weaponId as String?,
      armorId: armorId == _undefined ? this.armorId : armorId as String?,
      accessoryId: accessoryId == _undefined ? this.accessoryId : accessoryId as String?,
      statusEffects: statusEffects ?? this.statusEffects,
    );
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    final stats = Stats.fromJson(json['baseStats'] as Map<String, dynamic>);
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      heroClass: HeroClass.values.firstWhere(
        (e) => e.name == json['heroClass'],
      ),
      spriteId: json['spriteId'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentHp: json['currentHp'] as int? ?? stats.maxHp,
      currentMp: json['currentMp'] as int? ?? stats.maxMp,
      baseStats: stats,
      xp: json['xp'] as int? ?? 0,
      skillIds: (json['skillIds'] as List<dynamic>).cast<String>(),
      weaponId: json['weaponId'] as String?,
      armorId: json['armorId'] as String?,
      accessoryId: json['accessoryId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'heroClass': heroClass.name,
        'spriteId': spriteId,
        'level': level,
        'currentHp': currentHp,
        'currentMp': currentMp,
        'baseStats': baseStats.toJson(),
        'xp': xp,
        'skillIds': skillIds,
        'weaponId': weaponId,
        'armorId': armorId,
        'accessoryId': accessoryId,
      };
}
