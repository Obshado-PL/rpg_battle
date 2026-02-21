import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/character.dart';
import '../models/encounter.dart';
import '../models/enemy.dart';
import '../models/equipment.dart';
import '../models/item.dart';
import '../models/skill.dart';
import '../models/stats.dart';

class GameData {
  late final Map<String, Skill> skills;
  late final Map<String, Enemy> enemyTemplates;
  late final Map<String, Item> items;
  late final List<Encounter> encounters;
  late final Map<String, Equipment> equipment;
  late final List<Character> defaultParty;

  Future<void> load() async {
    skills = await _loadSkills();
    enemyTemplates = await _loadEnemies();
    items = await _loadItems();
    encounters = await _loadEncounters();
    equipment = await _loadEquipment();
    defaultParty = _createDefaultParty();
  }

  Future<Map<String, Skill>> _loadSkills() async {
    final jsonStr = await rootBundle.loadString('assets/data/skills.json');
    final list = json.decode(jsonStr) as List;
    final map = <String, Skill>{};
    for (final entry in list) {
      final skill = Skill.fromJson(entry as Map<String, dynamic>);
      map[skill.id] = skill;
    }
    return map;
  }

  Future<Map<String, Enemy>> _loadEnemies() async {
    final jsonStr = await rootBundle.loadString('assets/data/enemies.json');
    final list = json.decode(jsonStr) as List;
    final map = <String, Enemy>{};
    for (final entry in list) {
      final enemy = Enemy.fromJson(entry as Map<String, dynamic>);
      map[enemy.id] = enemy;
    }
    return map;
  }

  Future<Map<String, Item>> _loadItems() async {
    final jsonStr = await rootBundle.loadString('assets/data/items.json');
    final list = json.decode(jsonStr) as List;
    final map = <String, Item>{};
    for (final entry in list) {
      final item = Item.fromJson(entry as Map<String, dynamic>);
      map[item.id] = item;
    }
    return map;
  }

  Future<List<Encounter>> _loadEncounters() async {
    final jsonStr = await rootBundle.loadString('assets/data/encounters.json');
    final list = json.decode(jsonStr) as List;
    return list
        .map((e) => Encounter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, Equipment>> _loadEquipment() async {
    final jsonStr = await rootBundle.loadString('assets/data/equipment.json');
    final list = json.decode(jsonStr) as List;
    final map = <String, Equipment>{};
    for (final entry in list) {
      final eq = Equipment.fromJson(entry as Map<String, dynamic>);
      map[eq.id] = eq;
    }
    return map;
  }

  /// Create enemy instances from template for a given encounter.
  /// Each enemy gets a unique runtime ID.
  List<Enemy> createEnemiesForEncounter(Encounter encounter) {
    final enemies = <Enemy>[];
    final counts = <String, int>{};

    for (final enemyId in encounter.enemyIds) {
      final template = enemyTemplates[enemyId];
      if (template == null) continue;

      counts[enemyId] = (counts[enemyId] ?? 0) + 1;
      final count = counts[enemyId]!;
      final suffix = encounter.enemyIds
                  .where((id) => id == enemyId)
                  .length >
              1
          ? ' ${String.fromCharCode(64 + count)}' // A, B, C...
          : '';

      enemies.add(template.copyWith(
        id: '${enemyId}_$count',
        name: '${template.name}$suffix',
        currentHp: template.stats.maxHp,
      ));
    }

    return enemies;
  }

  List<Character> _createDefaultParty() {
    return [
      Character(
        id: 'hero_warrior',
        name: 'Roland',
        heroClass: HeroClass.warrior,
        level: 1,
        currentHp: 120,
        currentMp: 30,
        baseStats: const Stats(
          maxHp: 120,
          maxMp: 30,
          attack: 18,
          defense: 14,
          magicAttack: 6,
          magicDefense: 8,
          speed: 10,
        ),
        xp: 0,
        skillIds: ['warrior_slash', 'warrior_power_strike'],
        weaponId: 'wooden_sword',
        armorId: 'leather_vest',
      ),
      Character(
        id: 'hero_mage',
        name: 'Lyra',
        heroClass: HeroClass.mage,
        level: 1,
        currentHp: 70,
        currentMp: 80,
        baseStats: const Stats(
          maxHp: 70,
          maxMp: 80,
          attack: 6,
          defense: 7,
          magicAttack: 20,
          magicDefense: 15,
          speed: 12,
        ),
        xp: 0,
        skillIds: ['mage_fireball', 'mage_ice_storm'],
        weaponId: 'apprentice_staff',
        armorId: 'mage_robe',
      ),
      Character(
        id: 'hero_healer',
        name: 'Sera',
        heroClass: HeroClass.healer,
        level: 1,
        currentHp: 90,
        currentMp: 60,
        baseStats: const Stats(
          maxHp: 90,
          maxMp: 60,
          attack: 7,
          defense: 10,
          magicAttack: 14,
          magicDefense: 16,
          speed: 11,
        ),
        xp: 0,
        skillIds: ['healer_heal', 'healer_revive'],
        weaponId: 'apprentice_staff',
        armorId: 'leather_vest',
        accessoryId: 'prayer_beads',
      ),
      Character(
        id: 'hero_rogue',
        name: 'Kael',
        heroClass: HeroClass.rogue,
        level: 1,
        currentHp: 85,
        currentMp: 40,
        baseStats: const Stats(
          maxHp: 85,
          maxMp: 40,
          attack: 15,
          defense: 9,
          magicAttack: 8,
          magicDefense: 10,
          speed: 20,
        ),
        xp: 0,
        skillIds: ['rogue_backstab', 'rogue_poison_dart'],
        weaponId: 'wooden_sword',
        armorId: 'shadow_cloak',
        accessoryId: 'rusty_dagger',
      ),
    ];
  }
}
