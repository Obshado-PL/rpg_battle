import 'stats.dart';
import 'status_effect.dart';

enum AiBehavior { aggressive, defensive, random, boss }

class Enemy {
  final String id;
  final String name;
  final int currentHp;
  final Stats stats;
  final AiBehavior behavior;
  final List<String> skillIds;
  final int xpReward;
  final int goldReward;
  final String spriteColor;
  final List<StatusEffect> statusEffects;

  const Enemy({
    required this.id,
    required this.name,
    required this.currentHp,
    required this.stats,
    required this.behavior,
    required this.skillIds,
    required this.xpReward,
    required this.goldReward,
    required this.spriteColor,
    this.statusEffects = const [],
  });

  bool get isAlive => currentHp > 0;
  double get hpPercent => currentHp / stats.maxHp;

  Enemy copyWith({
    String? id,
    String? name,
    int? currentHp,
    Stats? stats,
    AiBehavior? behavior,
    List<String>? skillIds,
    int? xpReward,
    int? goldReward,
    String? spriteColor,
    List<StatusEffect>? statusEffects,
  }) {
    return Enemy(
      id: id ?? this.id,
      name: name ?? this.name,
      currentHp: currentHp ?? this.currentHp,
      stats: stats ?? this.stats,
      behavior: behavior ?? this.behavior,
      skillIds: skillIds ?? this.skillIds,
      xpReward: xpReward ?? this.xpReward,
      goldReward: goldReward ?? this.goldReward,
      spriteColor: spriteColor ?? this.spriteColor,
      statusEffects: statusEffects ?? this.statusEffects,
    );
  }

  factory Enemy.fromJson(Map<String, dynamic> json) {
    final stats = Stats.fromJson(json['stats'] as Map<String, dynamic>);
    return Enemy(
      id: json['id'] as String,
      name: json['name'] as String,
      currentHp: stats.maxHp,
      stats: stats,
      behavior: AiBehavior.values.firstWhere(
        (e) => e.name == json['behavior'],
      ),
      skillIds: (json['skillIds'] as List<dynamic>?)?.cast<String>() ?? [],
      xpReward: json['xpReward'] as int,
      goldReward: json['goldReward'] as int,
      spriteColor: json['spriteColor'] as String? ?? '0xFF4CAF50',
    );
  }
}
