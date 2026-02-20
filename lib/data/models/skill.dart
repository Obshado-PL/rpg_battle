enum SkillType { physical, magical, healing }

enum TargetType { singleEnemy, allEnemies, singleAlly, allAllies, self_ }

class Skill {
  final String id;
  final String name;
  final String description;
  final SkillType type;
  final TargetType targetType;
  final int mpCost;
  final int power;
  final String animationKey;
  final double accuracy;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetType,
    required this.mpCost,
    required this.power,
    required this.animationKey,
    this.accuracy = 1.0,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: SkillType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      targetType: TargetType.values.firstWhere(
        (e) => e.name == json['targetType'],
      ),
      mpCost: json['mpCost'] as int,
      power: json['power'] as int,
      animationKey: json['animationKey'] as String,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 1.0,
    );
  }

  bool get isOffensive => type == SkillType.physical || type == SkillType.magical;
  bool get isHealing => type == SkillType.healing;
  bool get isAoe => targetType == TargetType.allEnemies || targetType == TargetType.allAllies;
}
