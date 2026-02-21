import 'character.dart';
import 'item.dart';

class SaveData {
  final int version;
  final List<Character> party;
  final List<InventorySlot> inventory;
  final int gold;
  final Set<String> clearedEncounters;
  final Set<String> ownedEquipment;
  final String savedAt;

  const SaveData({
    this.version = 1,
    required this.party,
    required this.inventory,
    required this.gold,
    required this.clearedEncounters,
    required this.ownedEquipment,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'party': party.map((c) => c.toJson()).toList(),
        'inventory': inventory
            .map((s) => {'itemId': s.itemId, 'quantity': s.quantity})
            .toList(),
        'gold': gold,
        'clearedEncounters': clearedEncounters.toList(),
        'ownedEquipment': ownedEquipment.toList(),
        'savedAt': savedAt,
      };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    return SaveData(
      version: json['version'] as int? ?? 1,
      party: (json['party'] as List)
          .map((c) => Character.fromJson(c as Map<String, dynamic>))
          .toList(),
      inventory: (json['inventory'] as List)
          .map((s) => InventorySlot(
                itemId: s['itemId'] as String,
                quantity: s['quantity'] as int,
              ))
          .toList(),
      gold: json['gold'] as int,
      clearedEncounters:
          (json['clearedEncounters'] as List).cast<String>().toSet(),
      ownedEquipment:
          (json['ownedEquipment'] as List).cast<String>().toSet(),
      savedAt: json['savedAt'] as String,
    );
  }
}
