import '../data/models/character.dart';
import '../data/models/equipment.dart';
import '../data/models/stats.dart';

class EquipmentSystem {
  static Stats computeEffectiveStats(
    Character character,
    Map<String, Equipment> equipmentData,
  ) {
    final slotIds = [character.weaponId, character.armorId, character.accessoryId];
    final bonuses = <Stats>[];

    for (final eqId in slotIds) {
      if (eqId != null) {
        final eq = equipmentData[eqId];
        if (eq != null) bonuses.add(eq.statBonuses);
      }
    }

    if (bonuses.isEmpty) return character.baseStats;

    final base = character.baseStats;
    return Stats(
      maxHp: base.maxHp + bonuses.fold(0, (sum, b) => sum + b.maxHp),
      maxMp: base.maxMp + bonuses.fold(0, (sum, b) => sum + b.maxMp),
      attack: base.attack + bonuses.fold(0, (sum, b) => sum + b.attack),
      defense: base.defense + bonuses.fold(0, (sum, b) => sum + b.defense),
      magicAttack: base.magicAttack + bonuses.fold(0, (sum, b) => sum + b.magicAttack),
      magicDefense: base.magicDefense + bonuses.fold(0, (sum, b) => sum + b.magicDefense),
      speed: base.speed + bonuses.fold(0, (sum, b) => sum + b.speed),
    );
  }
}
