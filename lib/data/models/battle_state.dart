import 'character.dart';
import 'enemy.dart';
import 'item.dart';

enum BattlePhase {
  starting,
  playerInput,
  actionExecution,
  enemyTurn,
  victory,
  defeat,
  fled,
}

class BattleResult {
  final int totalXp;
  final int totalGold;
  final List<String> levelUps;

  const BattleResult({
    required this.totalXp,
    required this.totalGold,
    this.levelUps = const [],
  });
}

class BattleState {
  final List<Character> party;
  final List<Enemy> enemies;
  final BattlePhase phase;
  final List<String> turnOrder;
  final int currentTurnIndex;
  final List<String> battleLog;
  final List<InventorySlot> inventory;
  final BattleResult? result;
  final int roundNumber;
  final String? activeHeroId;

  const BattleState({
    required this.party,
    required this.enemies,
    required this.phase,
    required this.turnOrder,
    required this.currentTurnIndex,
    required this.battleLog,
    required this.inventory,
    this.result,
    this.roundNumber = 1,
    this.activeHeroId,
  });

  factory BattleState.initial() {
    return const BattleState(
      party: [],
      enemies: [],
      phase: BattlePhase.starting,
      turnOrder: [],
      currentTurnIndex: 0,
      battleLog: [],
      inventory: [],
    );
  }

  String? get currentActorId =>
      turnOrder.isNotEmpty && currentTurnIndex < turnOrder.length
          ? turnOrder[currentTurnIndex]
          : null;

  bool get isPlayerTurn => phase == BattlePhase.playerInput;
  bool get isBattleOver =>
      phase == BattlePhase.victory ||
      phase == BattlePhase.defeat ||
      phase == BattlePhase.fled;

  Character? get currentHero {
    final actorId = currentActorId;
    if (actorId == null) return null;
    try {
      return party.firstWhere((h) => h.id == actorId);
    } catch (_) {
      return null;
    }
  }

  BattleState copyWith({
    List<Character>? party,
    List<Enemy>? enemies,
    BattlePhase? phase,
    List<String>? turnOrder,
    int? currentTurnIndex,
    List<String>? battleLog,
    List<InventorySlot>? inventory,
    BattleResult? result,
    int? roundNumber,
    String? activeHeroId,
  }) {
    return BattleState(
      party: party ?? this.party,
      enemies: enemies ?? this.enemies,
      phase: phase ?? this.phase,
      turnOrder: turnOrder ?? this.turnOrder,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      battleLog: battleLog ?? this.battleLog,
      inventory: inventory ?? this.inventory,
      result: result ?? this.result,
      roundNumber: roundNumber ?? this.roundNumber,
      activeHeroId: activeHeroId ?? this.activeHeroId,
    );
  }
}
