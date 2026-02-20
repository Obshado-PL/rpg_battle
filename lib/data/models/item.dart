import 'skill.dart';

enum ItemEffect { restoreHp, restoreMp, revive }

class Item {
  final String id;
  final String name;
  final String description;
  final ItemEffect effect;
  final int power;
  final TargetType targetType;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.effect,
    required this.power,
    required this.targetType,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      effect: ItemEffect.values.firstWhere(
        (e) => e.name == json['effect'],
      ),
      power: json['power'] as int,
      targetType: TargetType.values.firstWhere(
        (e) => e.name == json['targetType'],
      ),
    );
  }
}

class InventorySlot {
  final String itemId;
  final int quantity;

  const InventorySlot({
    required this.itemId,
    required this.quantity,
  });

  InventorySlot copyWith({String? itemId, int? quantity}) {
    return InventorySlot(
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
    );
  }
}
