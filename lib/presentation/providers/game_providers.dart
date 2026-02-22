import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/game_data.dart';
import '../../data/datasources/save_manager.dart';
import '../../data/models/battle_action.dart';
import '../../data/models/battle_state.dart';
import '../../data/models/character.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/encounter.dart';
import '../../data/models/equipment.dart';
import '../../data/models/item.dart';
import '../../data/models/save_data.dart';
import '../../domain/battle_engine.dart' show BattleAnimationEvent, BattleEngine;
import '../../domain/skill_tree_system.dart';
import '../../domain/damage_calculator.dart';
import '../../domain/enemy_ai.dart';
import '../../domain/equipment_system.dart';
import '../../domain/level_system.dart';
import '../../domain/sound_manager.dart';
import '../../domain/turn_manager.dart';

/// Sound manager singleton.
final soundManagerProvider = Provider<SoundManager>((ref) {
  final manager = SoundManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Sound muted state.
final soundMutedProvider = StateProvider<bool>((ref) => false);

/// Global game data loaded at startup.
final gameDataProvider = Provider<GameData>((ref) {
  throw UnimplementedError('Must be overridden with loaded GameData');
});

/// Save manager for persisting game state.
final saveManagerProvider = Provider<SaveManager>((ref) {
  throw UnimplementedError('Must be overridden with loaded SaveManager');
});

/// Difficulty setting.
final difficultyProvider = StateProvider<Difficulty>((ref) => Difficulty.normal);

/// Bestiary: enemy defeat counts.
final bestiaryProvider =
    StateNotifierProvider<BestiaryNotifier, Map<String, int>>((ref) {
  return BestiaryNotifier();
});

class BestiaryNotifier extends StateNotifier<Map<String, int>> {
  BestiaryNotifier() : super({});
  BestiaryNotifier.fromMap(super.saved);

  void recordDefeats(List<String> enemyTemplateIds) {
    final updated = Map<String, int>.from(state);
    for (final id in enemyTemplateIds) {
      updated[id] = (updated[id] ?? 0) + 1;
    }
    state = updated;
  }

  void reset() => state = {};
}

/// Skill tree system provider.
final skillTreeSystemProvider = Provider<SkillTreeSystem>((ref) {
  final gameData = ref.watch(gameDataProvider);
  return SkillTreeSystem(gameData.skillTrees);
});

/// Skill tree choices: key = "warrior_tier1", value = skill_id.
final skillTreeChoicesProvider =
    StateNotifierProvider<SkillTreeChoicesNotifier, Map<String, String>>(
        (ref) => SkillTreeChoicesNotifier());

class SkillTreeChoicesNotifier extends StateNotifier<Map<String, String>> {
  SkillTreeChoicesNotifier() : super({});
  SkillTreeChoicesNotifier.fromMap(super.saved);

  void choose(String tierKey, String skillId) {
    state = {...state, tierKey: skillId};
  }

  void resetClass(String heroClassName) {
    state = Map.fromEntries(
      state.entries.where((e) => !e.key.startsWith(heroClassName)),
    );
  }

  void reset() => state = {};
}

/// Set of hero IDs the player owns (starters + gacha pulls).
final ownedHeroIdsProvider =
    StateNotifierProvider<OwnedHeroIdsNotifier, Set<String>>((ref) {
  return OwnedHeroIdsNotifier();
});

class OwnedHeroIdsNotifier extends StateNotifier<Set<String>> {
  OwnedHeroIdsNotifier()
      : super(GameData.starterHeroIds.toSet());

  OwnedHeroIdsNotifier.fromSet(super.saved);

  void add(String heroId) => state = {...state, heroId};

  void reset() => state = GameData.starterHeroIds.toSet();
}

/// Bench roster: owned heroes NOT in the active party.
final rosterProvider =
    StateNotifierProvider<RosterNotifier, List<Character>>((ref) {
  return RosterNotifier();
});

class RosterNotifier extends StateNotifier<List<Character>> {
  RosterNotifier() : super([]);
  RosterNotifier.fromList(super.saved);

  void addHero(Character hero) => state = [...state, hero];

  void removeHero(String heroId) =>
      state = state.where((h) => h.id != heroId).toList();

  void updateHero(Character hero) {
    state = [
      for (final h in state)
        if (h.id == hero.id) hero else h,
    ];
  }

  void reset() => state = [];
}

/// Collect current state and save to disk.
Future<void> collectAndSave(WidgetRef ref) async {
  final saveManager = ref.read(saveManagerProvider);
  final data = SaveData(
    party: ref.read(partyProvider),
    roster: ref.read(rosterProvider),
    ownedHeroIds: ref.read(ownedHeroIdsProvider),
    inventory: ref.read(inventoryProvider),
    gold: ref.read(goldProvider),
    clearedEncounters: ref.read(clearedEncountersProvider),
    ownedEquipment: ref.read(ownedEquipmentProvider),
    difficulty: ref.read(difficultyProvider),
    bestiaryDefeats: ref.read(bestiaryProvider),
    skillTreeChoices: ref.read(skillTreeChoicesProvider),
    savedAt: DateTime.now().toIso8601String(),
  );
  await saveManager.save(data);
}

/// Player's current party state, persists across battles.
final partyProvider = StateNotifierProvider<PartyNotifier, List<Character>>(
  (ref) {
    final gameData = ref.watch(gameDataProvider);
    return PartyNotifier(gameData.defaultParty, equipmentData: gameData.equipment);
  },
);

/// Set of equipment IDs the player owns.
final ownedEquipmentProvider =
    StateNotifierProvider<OwnedEquipmentNotifier, Set<String>>((ref) {
  return OwnedEquipmentNotifier();
});

class OwnedEquipmentNotifier extends StateNotifier<Set<String>> {
  OwnedEquipmentNotifier()
      : super({
          // Starter equipment
          'wooden_sword',
          'apprentice_staff',
          'leather_vest',
          'mage_robe',
          'shadow_cloak',
          'prayer_beads',
          'rusty_dagger',
        });

  OwnedEquipmentNotifier.fromSet(super.saved);

  void add(String equipmentId) => state = {...state, equipmentId};

  void addAll(Iterable<String> ids) => state = {...state, ...ids};

  void reset() {
    state = {
      'wooden_sword',
      'apprentice_staff',
      'leather_vest',
      'mage_robe',
      'shadow_cloak',
      'prayer_beads',
      'rusty_dagger',
    };
  }
}

class PartyNotifier extends StateNotifier<List<Character>> {
  final Map<String, Equipment> _equipmentData;

  PartyNotifier(super.party, {Map<String, Equipment>? equipmentData})
      : _equipmentData = equipmentData ?? {};

  void updateParty(List<Character> party) => state = party;

  void healAll() {
    state = state.map((h) {
      final eff = EquipmentSystem.computeEffectiveStats(h, _equipmentData);
      return h.copyWith(
        currentHp: eff.maxHp,
        currentMp: eff.maxMp,
      );
    }).toList();
  }

  void applyBattleResult(List<Character> updatedParty) {
    state = updatedParty;
  }

  void updateHeroSkills(String heroId, List<String> skillIds) {
    state = state.map((h) {
      if (h.id != heroId) return h;
      return h.copyWith(skillIds: skillIds);
    }).toList();
  }

  void equip(String heroId, Equipment eq) {
    state = state.map((h) {
      if (h.id != heroId) return h;
      switch (eq.slotType) {
        case EquipmentSlotType.weapon:
          return h.copyWith(weaponId: eq.id);
        case EquipmentSlotType.armor:
          return h.copyWith(armorId: eq.id);
        case EquipmentSlotType.accessory:
          return h.copyWith(accessoryId: eq.id);
      }
    }).toList();
  }

  void unequip(String heroId, EquipmentSlotType slot) {
    state = state.map((h) {
      if (h.id != heroId) return h;
      switch (slot) {
        case EquipmentSlotType.weapon:
          return h.copyWith(weaponId: null);
        case EquipmentSlotType.armor:
          return h.copyWith(armorId: null);
        case EquipmentSlotType.accessory:
          return h.copyWith(accessoryId: null);
      }
    }).toList();
  }
}

/// Inventory state.
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventorySlot>>((ref) {
  return InventoryNotifier();
});

class InventoryNotifier extends StateNotifier<List<InventorySlot>> {
  InventoryNotifier()
      : super([
          const InventorySlot(itemId: 'potion', quantity: 5),
          const InventorySlot(itemId: 'hi_potion', quantity: 2),
          const InventorySlot(itemId: 'ether', quantity: 3),
          const InventorySlot(itemId: 'phoenix_down', quantity: 2),
        ]);

  InventoryNotifier.fromList(super.saved);

  void updateInventory(List<InventorySlot> inventory) => state = inventory;

  void addItem(String itemId, [int quantity = 1]) {
    final existing = state.indexWhere((s) => s.itemId == itemId);
    if (existing >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existing)
            state[i].copyWith(quantity: state[i].quantity + quantity)
          else
            state[i],
      ];
    } else {
      state = [...state, InventorySlot(itemId: itemId, quantity: quantity)];
    }
  }
}

/// Gold tracker.
final goldProvider = StateProvider<int>((ref) => 100);

/// Encounters cleared tracker.
final clearedEncountersProvider = StateProvider<Set<String>>((ref) => {});

/// Battle speed multiplier: 1.0 = normal, 0.5 = 2x, 0.33 = 3x.
final battleSpeedProvider = StateProvider<double>((ref) => 1.0);

/// Auto-battle toggle.
final autoBattleProvider = StateProvider<bool>((ref) => false);

/// Battle state management.
final battleProvider =
    StateNotifierProvider<BattleNotifier, BattleState>((ref) {
  final gameData = ref.watch(gameDataProvider);
  return BattleNotifier(
    engine: BattleEngine(
      turnManager: TurnManager(equipment: gameData.equipment),
      damageCalculator: DamageCalculator(),
      enemyAi: EnemyAi(),
      skills: gameData.skills,
      items: gameData.items,
      equipment: gameData.equipment,
    ),
    gameData: gameData,
    levelSystem: LevelSystem(),
  );
});

class BattleNotifier extends StateNotifier<BattleState> {
  final BattleEngine engine;
  final GameData gameData;
  final LevelSystem levelSystem;

  /// Set by BattleScreen to play animations before state commits.
  Future<void> Function(List<BattleAnimationEvent>)? onPlayAnimations;

  /// Speed multiplier: 1.0 = normal, 0.5 = 2x, 0.33 = 3x.
  double speedMultiplier = 1.0;

  Duration _scaled(Duration d) =>
      Duration(milliseconds: (d.inMilliseconds * speedMultiplier).round());

  BattleNotifier({
    required this.engine,
    required this.gameData,
    required this.levelSystem,
  }) : super(BattleState.initial());

  void startBattle({
    required Encounter encounter,
    required List<Character> party,
    required List<InventorySlot> inventory,
    Difficulty difficulty = Difficulty.normal,
  }) {
    final enemies = gameData.createEnemiesForEncounter(
      encounter,
      difficulty: difficulty,
    );
    state = engine.initBattle(
      party: party,
      enemies: enemies,
      inventory: inventory,
    );

    // Start first round after a brief delay
    Future.delayed(_scaled(const Duration(milliseconds: 500)), () {
      if (mounted) {
        state = engine.startRound(state);
      }
    });
  }

  Future<void> submitPlayerAction(BattleAction action) async {
    state = state.copyWith(phase: BattlePhase.actionExecution);

    await Future.delayed(_scaled(const Duration(milliseconds: 200)));

    final result = engine.executeAction(state, action);

    // Play animations BEFORE applying state so HP bars drop after hit visuals
    if (result.animations.isNotEmpty && onPlayAnimations != null) {
      await onPlayAnimations!(result.animations);
    }

    state = result.state;

    if (state.isBattleOver) return;

    await Future.delayed(_scaled(const Duration(milliseconds: 400)));
    state = engine.advanceTurn(state);

    // Auto-execute enemy turns
    if (state.phase == BattlePhase.enemyTurn) {
      await _executeEnemyTurns();
    }
  }

  Future<void> _executeEnemyTurns() async {
    while (mounted && state.phase == BattlePhase.enemyTurn) {
      await Future.delayed(_scaled(const Duration(milliseconds: 600)));

      final enemyAction = engine.getEnemyAction(state);
      final result = engine.executeAction(state, enemyAction);

      // Play animations BEFORE applying state
      if (result.animations.isNotEmpty && onPlayAnimations != null) {
        await onPlayAnimations!(result.animations);
      }

      state = result.state;

      if (state.isBattleOver) return;

      await Future.delayed(_scaled(const Duration(milliseconds: 400)));
      state = engine.advanceTurn(state);
    }
  }

  /// Apply XP and level ups after victory. Strip status effects.
  List<Character> applyVictoryRewards(List<Character> party) {
    if (state.result == null) return party;
    final xpPerHero = state.result!.totalXp ~/ party.length.clamp(1, 99);

    return party.map((hero) {
      var h = hero.copyWith(statusEffects: []);
      if (h.isAlive) {
        h = levelSystem.applyXp(h, xpPerHero);
      }
      return h;
    }).toList();
  }
}
