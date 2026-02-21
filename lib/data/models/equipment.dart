import 'character.dart';
import 'stats.dart';

enum EquipmentSlotType { weapon, armor, accessory }

class Equipment {
  final String id;
  final String name;
  final String description;
  final EquipmentSlotType slotType;
  final Stats statBonuses;
  final int price;
  final List<HeroClass> usableBy;

  const Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.slotType,
    required this.statBonuses,
    required this.price,
    required this.usableBy,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      slotType: EquipmentSlotType.values.firstWhere(
        (e) => e.name == json['slotType'],
      ),
      statBonuses: Stats.fromJson(json['statBonuses'] as Map<String, dynamic>),
      price: json['price'] as int? ?? 0,
      usableBy: (json['usableBy'] as List<dynamic>)
          .map((e) => HeroClass.values.firstWhere((h) => h.name == e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'slotType': slotType.name,
        'statBonuses': statBonuses.toJson(),
        'price': price,
        'usableBy': usableBy.map((e) => e.name).toList(),
      };
}
