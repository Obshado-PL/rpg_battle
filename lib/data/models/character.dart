import 'stats.dart';

enum HeroClass { warrior, mage, healer, rogue }

class Character {
  final String id;
  final String name;
  final HeroClass heroClass;
  final int level;
  final int currentHp;
  final int currentMp;
  final Stats baseStats;
  final int xp;
  final List<String> skillIds;
  final bool isDefending;

  const Character({
    required this.id,
    required this.name,
    required this.heroClass,
    required this.level,
    required this.currentHp,
    required this.currentMp,
    required this.baseStats,
    required this.xp,
    required this.skillIds,
    this.isDefending = false,
  });

  bool get isAlive => currentHp > 0;
  double get hpPercent => currentHp / baseStats.maxHp;
  double get mpPercent => baseStats.maxMp > 0 ? currentMp / baseStats.maxMp : 0;

  Character copyWith({
    String? id,
    String? name,
    HeroClass? heroClass,
    int? level,
    int? currentHp,
    int? currentMp,
    Stats? baseStats,
    int? xp,
    List<String>? skillIds,
    bool? isDefending,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      heroClass: heroClass ?? this.heroClass,
      level: level ?? this.level,
      currentHp: currentHp ?? this.currentHp,
      currentMp: currentMp ?? this.currentMp,
      baseStats: baseStats ?? this.baseStats,
      xp: xp ?? this.xp,
      skillIds: skillIds ?? this.skillIds,
      isDefending: isDefending ?? this.isDefending,
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
      level: json['level'] as int? ?? 1,
      currentHp: json['currentHp'] as int? ?? stats.maxHp,
      currentMp: json['currentMp'] as int? ?? stats.maxMp,
      baseStats: stats,
      xp: json['xp'] as int? ?? 0,
      skillIds: (json['skillIds'] as List<dynamic>).cast<String>(),
    );
  }
}
