import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/game_data.dart';
import '../../data/models/battle_action.dart';
import '../../data/models/battle_state.dart';
import '../../data/models/character.dart';
import '../../data/models/encounter.dart';
import '../../data/models/item.dart';
import '../../domain/battle_engine.dart';
import '../../domain/damage_calculator.dart';
import '../../domain/enemy_ai.dart';
import '../../domain/level_system.dart';
import '../../domain/turn_manager.dart';

/// Global game data loaded at startup.
final gameDataProvider = Provider<GameData>((ref) {
  throw UnimplementedError('Must be overridden with loaded GameData');
});

/// Player's current party state, persists across battles.
final partyProvider = StateNotifierProvider<PartyNotifier, List<Character>>(
  (ref) {
    final gameData = ref.watch(gameDataProvider);
    return PartyNotifier(gameData.defaultParty);
  },
);

class PartyNotifier extends StateNotifier<List<Character>> {
  PartyNotifier(super.party);

  void updateParty(List<Character> party) => state = party;

  void healAll() {
    state = state.map((h) {
      return h.copyWith(
        currentHp: h.baseStats.maxHp,
        currentMp: h.baseStats.maxMp,
      );
    }).toList();
  }

  void applyBattleResult(List<Character> updatedParty) {
    state = updatedParty;
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

  void updateInventory(List<InventorySlot> inventory) => state = inventory;
}

/// Gold tracker.
final goldProvider = StateProvider<int>((ref) => 100);

/// Encounters cleared tracker.
final clearedEncountersProvider = StateProvider<Set<String>>((ref) => {});

/// Battle state management.
final battleProvider =
    StateNotifierProvider<BattleNotifier, BattleState>((ref) {
  final gameData = ref.watch(gameDataProvider);
  return BattleNotifier(
    engine: BattleEngine(
      turnManager: TurnManager(),
      damageCalculator: DamageCalculator(),
      enemyAi: EnemyAi(),
      skills: gameData.skills,
      items: gameData.items,
    ),
    gameData: gameData,
    levelSystem: LevelSystem(),
  );
});

class BattleNotifier extends StateNotifier<BattleState> {
  final BattleEngine engine;
  final GameData gameData;
  final LevelSystem levelSystem;

  BattleNotifier({
    required this.engine,
    required this.gameData,
    required this.levelSystem,
  }) : super(BattleState.initial());

  void startBattle({
    required Encounter encounter,
    required List<Character> party,
    required List<InventorySlot> inventory,
  }) {
    final enemies = gameData.createEnemiesForEncounter(encounter);
    state = engine.initBattle(
      party: party,
      enemies: enemies,
      inventory: inventory,
    );

    // Start first round after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        state = engine.startRound(state);
      }
    });
  }

  Future<void> submitPlayerAction(BattleAction action) async {
    state = state.copyWith(phase: BattlePhase.actionExecution);

    // Small delay for animation feel
    await Future.delayed(const Duration(milliseconds: 300));

    final result = engine.executeAction(state, action);
    state = result.state;

    if (state.isBattleOver) return;

    await Future.delayed(const Duration(milliseconds: 500));
    state = engine.advanceTurn(state);

    // Auto-execute enemy turns
    if (state.phase == BattlePhase.enemyTurn) {
      await _executeEnemyTurns();
    }
  }

  Future<void> _executeEnemyTurns() async {
    while (mounted && state.phase == BattlePhase.enemyTurn) {
      await Future.delayed(const Duration(milliseconds: 800));

      final enemyAction = engine.getEnemyAction(state);
      final result = engine.executeAction(state, enemyAction);
      state = result.state;

      if (state.isBattleOver) return;

      await Future.delayed(const Duration(milliseconds: 500));
      state = engine.advanceTurn(state);
    }
  }

  /// Apply XP and level ups after victory.
  List<Character> applyVictoryRewards(List<Character> party) {
    if (state.result == null) return party;
    final xpPerHero = state.result!.totalXp ~/ party.length.clamp(1, 99);

    return party.map((hero) {
      if (hero.isAlive) {
        return levelSystem.applyXp(hero, xpPerHero);
      }
      return hero;
    }).toList();
  }
}
