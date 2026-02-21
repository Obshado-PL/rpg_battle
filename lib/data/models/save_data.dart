import 'character.dart';
import 'difficulty.dart';
import 'item.dart';

class SaveData {
  final int version;
  final List<Character> party;
  final List<InventorySlot> inventory;
  final int gold;
  final Set<String> clearedEncounters;
  final Set<String> ownedEquipment;
  final Difficulty difficulty;
  final Map<String, int> bestiaryDefeats;
  final Map<String, String> skillTreeChoices;
  final String savedAt;

  const SaveData({
    this.version = 3,
    required this.party,
    required this.inventory,
    required this.gold,
    required this.clearedEncounters,
    required this.ownedEquipment,
    this.difficulty = Difficulty.normal,
    this.bestiaryDefeats = const {},
    this.skillTreeChoices = const {},
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
        'difficulty': difficulty.name,
        'bestiaryDefeats': bestiaryDefeats,
        'skillTreeChoices': skillTreeChoices,
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
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == (json['difficulty'] as String?),
        orElse: () => Difficulty.normal,
      ),
      bestiaryDefeats: (json['bestiaryDefeats'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      skillTreeChoices: (json['skillTreeChoices'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      savedAt: json['savedAt'] as String,
    );
  }
}
