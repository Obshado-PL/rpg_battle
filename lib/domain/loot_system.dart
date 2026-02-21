import 'dart:math';

import '../data/models/loot_table.dart';

class ItemLoot {
  final String itemId;
  final int quantity;
  const ItemLoot({required this.itemId, required this.quantity});
}

class LootResult {
  final List<ItemLoot> items;
  final List<String> equipmentIds;

  const LootResult({this.items = const [], this.equipmentIds = const []});

  bool get isEmpty => items.isEmpty && equipmentIds.isEmpty;
}

class LootSystem {
  final Random _random;
  LootSystem({Random? random}) : _random = random ?? Random();

  LootResult rollLoot({
    required List<LootDrop> lootTable,
    required Set<String> ownedEquipment,
    double rewardScale = 1.0,
  }) {
    final items = <String, int>{};
    final equipment = <String>[];

    for (final drop in lootTable) {
      final adjustedChance =
          (drop.dropChance * rewardScale).clamp(0.0, 1.0);
      if (_random.nextDouble() < adjustedChance) {
        if (drop.isEquipment) {
          if (!ownedEquipment.contains(drop.itemId) &&
              !equipment.contains(drop.itemId)) {
            equipment.add(drop.itemId);
          }
        } else {
          final qty = drop.minQuantity +
              (drop.maxQuantity > drop.minQuantity
                  ? _random.nextInt(
                      drop.maxQuantity - drop.minQuantity + 1)
                  : 0);
          items[drop.itemId] = (items[drop.itemId] ?? 0) + qty;
        }
      }
    }

    return LootResult(
      items: items.entries
          .map((e) => ItemLoot(itemId: e.key, quantity: e.value))
          .toList(),
      equipmentIds: equipment,
    );
  }
}
