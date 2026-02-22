import 'status_effect.dart';

enum SkillType { physical, magical, healing }

enum TargetType { singleEnemy, allEnemies, singleAlly, allAllies, self_ }

enum SkillElement { fire, ice, lightning, dark, holy, none }

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
  final StatusEffectType? appliesEffect;
  final int effectDuration;
  final int effectValue;
  final double effectChance;
  final SkillElement element;

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
    this.appliesEffect,
    this.effectDuration = 3,
    this.effectValue = 0,
    this.effectChance = 1.0,
    this.element = SkillElement.none,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    final effectStr = json['appliesEffect'] as String?;
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
      appliesEffect: effectStr != null
          ? StatusEffectType.values.firstWhere((e) => e.name == effectStr)
          : null,
      effectDuration: json['effectDuration'] as int? ?? 3,
      effectValue: json['effectValue'] as int? ?? 0,
      effectChance: (json['effectChance'] as num?)?.toDouble() ?? 1.0,
      element: json['element'] != null
          ? SkillElement.values.firstWhere((e) => e.name == json['element'])
          : SkillElement.none,
    );
  }

  bool get isOffensive => type == SkillType.physical || type == SkillType.magical;
  bool get isHealing => type == SkillType.healing;
  bool get isAoe => targetType == TargetType.allEnemies || targetType == TargetType.allAllies;
}
