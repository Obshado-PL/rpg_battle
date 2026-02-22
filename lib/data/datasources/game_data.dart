import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/character.dart';
import '../models/difficulty.dart';
import '../models/encounter.dart';
import '../models/enemy.dart';
import '../models/equipment.dart';
import '../models/hero_template.dart';
import '../models/item.dart';
import '../models/loot_table.dart';
import '../models/skill.dart';
import '../models/skill_tree.dart';
import '../models/stats.dart';
import '../models/story_dialogue.dart';

class GameData {
  static const starterHeroIds = [
    'hero_warrior',
    'hero_mage',
    'hero_healer',
    'hero_rogue',
  ];

  late final Map<String, Skill> skills;
  late final Map<String, Enemy> enemyTemplates;
  late final Map<String, Item> items;
  late final List<Encounter> encounters;
  late final Map<String, Equipment> equipment;
  late final Map<String, List<LootDrop>> lootTables;
  late final List<SkillTree> skillTrees;
  late final Map<String, EncounterStory> storyData;
  late final Map<String, HeroTemplate> heroTemplates;
  late final List<Character> defaultParty;

  Future<void> load() async {
    skills = await _loadSkills();
    enemyTemplates = await _loadEnemies();
    items = await _loadItems();
    encounters = await _loadEncounters();
    equipment = await _loadEquipment();
    lootTables = await _loadLootTables();
    skillTrees = await _loadSkillTrees();
    storyData = await _loadStory();
    heroTemplates = await _loadHeroTemplates();
    defaultParty = _createDefaultParty();
  }

  Future<Map<String, HeroTemplate>> _loadHeroTemplates() async {
    final jsonStr = await rootBundle.loadString('assets/data/heroes.json');
    final list = json.decode(jsonStr) as List;
    final map = <String, HeroTemplate>{};
    for (final entry in list) {
      final template = HeroTemplate.fromJson(entry as Map<String, dynamic>);
      map[template.id] = template;
    }
    return map;
  }

  Character createCharacterFromTemplate(String heroId) {
    final template = heroTemplates[heroId]!;
    return Character(
      id: template.id,
      name: template.name,
      heroClass: template.heroClass,
      spriteId: template.spriteId,
      level: 1,
      currentHp: template.baseStats.maxHp,
      currentMp: template.baseStats.maxMp,
      baseStats: template.baseStats,
      xp: 0,
      skillIds: template.startingSkillIds,
      weaponId: template.startingWeaponId,
      armorId: template.startingArmorId,
      accessoryId: template.startingAccessoryId,
    );
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

  Future<Map<String, List<LootDrop>>> _loadLootTables() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/loot_tables.json');
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return map.map((key, value) {
      final drops = (value as List)
          .map((e) => LootDrop.fromJson(e as Map<String, dynamic>))
          .toList();
      return MapEntry(key, drops);
    });
  }

  Future<List<SkillTree>> _loadSkillTrees() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/skill_trees.json');
    final list = json.decode(jsonStr) as List;
    return list
        .map((e) => SkillTree.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, EncounterStory>> _loadStory() async {
    final jsonStr = await rootBundle.loadString('assets/data/story.json');
    final list = json.decode(jsonStr) as List;
    final map = <String, EncounterStory>{};
    for (final entry in list) {
      final story =
          EncounterStory.fromJson(entry as Map<String, dynamic>);
      map[story.encounterId] = story;
    }
    return map;
  }

  /// Get combined loot table for all enemies in an encounter.
  List<LootDrop> getLootTableForEncounter(Encounter encounter) {
    final drops = <LootDrop>[];
    for (final enemyId in encounter.enemyIds) {
      final table = lootTables[enemyId];
      if (table != null) drops.addAll(table);
    }
    return drops;
  }

  /// Scale an enemy template's stats by the given difficulty config.
  Enemy _scaleEnemyForDifficulty(Enemy template, DifficultyConfig config) {
    if (config.difficulty == Difficulty.normal) return template;
    final s = config.enemyStatScale;
    return template.copyWith(
      stats: Stats(
        maxHp: (template.stats.maxHp * s).round().clamp(1, 99999),
        maxMp: (template.stats.maxMp * s).round().clamp(0, 99999),
        attack: (template.stats.attack * s).round().clamp(1, 9999),
        defense: (template.stats.defense * s).round().clamp(1, 9999),
        magicAttack: (template.stats.magicAttack * s).round().clamp(1, 9999),
        magicDefense: (template.stats.magicDefense * s).round().clamp(1, 9999),
        speed: (template.stats.speed * s).round().clamp(1, 9999),
      ),
      currentHp: (template.stats.maxHp * s).round().clamp(1, 99999),
      xpReward: (template.xpReward * config.rewardScale).round(),
      goldReward: (template.goldReward * config.rewardScale).round(),
    );
  }

  /// Create enemy instances from template for a given encounter.
  /// Each enemy gets a unique runtime ID.
  List<Enemy> createEnemiesForEncounter(
    Encounter encounter, {
    Difficulty difficulty = Difficulty.normal,
  }) {
    final config = DifficultyConfig.get(difficulty);
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

      final scaled = _scaleEnemyForDifficulty(template, config);
      enemies.add(scaled.copyWith(
        id: '${enemyId}_$count',
        name: '${template.name}$suffix',
        currentHp: scaled.stats.maxHp,
      ));
    }

    return enemies;
  }

  List<Character> _createDefaultParty() {
    return starterHeroIds.map(createCharacterFromTemplate).toList();
  }
}
