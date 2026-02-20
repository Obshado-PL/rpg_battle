import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/game_data.dart';
import '../../data/models/battle_action.dart';
import '../../data/models/battle_state.dart';
import '../../data/models/encounter.dart';
import '../../presentation/providers/game_providers.dart';
import '../widgets/battle/action_menu.dart';
import '../widgets/battle/battle_log.dart';
import '../widgets/battle/enemy_formation.dart';
import '../widgets/battle/party_status_bar.dart';
import '../widgets/battle/turn_order_bar.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final Encounter encounter;

  const BattleScreen({super.key, required this.encounter});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  final _actionMenuKey = GlobalKey<ActionMenuState>();
  MenuState _currentMenuState = MenuState.main;
  bool _battleStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBattle();
    });
  }

  void _startBattle() {
    final party = ref.read(partyProvider);
    final inventory = ref.read(inventoryProvider);
    ref.read(battleProvider.notifier).startBattle(
          encounter: widget.encounter,
          party: party,
          inventory: inventory,
        );
    setState(() => _battleStarted = true);
  }

  void _onActionSelected(BattleAction action) {
    ref.read(battleProvider.notifier).submitPlayerAction(action);
  }

  void _onEnemyTap(String enemyId) {
    if (_currentMenuState == MenuState.targetEnemy) {
      _actionMenuKey.currentState?.onTargetSelected(enemyId);
    }
  }

  void _onHeroTap(String heroId) {
    if (_currentMenuState == MenuState.targetAlly) {
      _actionMenuKey.currentState?.onTargetSelected(heroId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleProvider);
    final gameData = ref.watch(gameDataProvider);
    final gradStart =
        Color(int.parse(widget.encounter.backgroundGradientStart));
    final gradEnd = Color(int.parse(widget.encounter.backgroundGradientEnd));

    // Listen for battle end
    ref.listen<BattleState>(battleProvider, (prev, next) {
      if (next.phase == BattlePhase.victory) {
        _showVictoryDialog(next);
      } else if (next.phase == BattlePhase.defeat) {
        _showDefeatDialog();
      } else if (next.phase == BattlePhase.fled) {
        _showFledDialog();
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradStart, gradEnd, Colors.black],
          ),
        ),
        child: SafeArea(
          child: !_battleStarted || battleState.phase == BattlePhase.starting
              ? _buildStartingPhase()
              : _buildBattleUI(battleState, gameData),
        ),
      ),
    );
  }

  Widget _buildStartingPhase() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_martial_arts, size: 48, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Battle Start!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleUI(BattleState battleState, GameData gameData) {
    final isPlayerTurn = battleState.phase == BattlePhase.playerInput;
    final activeHero = battleState.currentHero;

    return Column(
      children: [
        // Turn order bar
        TurnOrderBar(
          turnOrder: battleState.turnOrder,
          currentTurnIndex: battleState.currentTurnIndex,
          party: battleState.party,
          enemies: battleState.enemies,
        ),

        // Round indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Round ${battleState.roundNumber}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (isPlayerTurn && activeHero != null)
                Text(
                  '${activeHero.name}\'s turn',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.yellow,
                      ),
                ),
              if (!isPlayerTurn && !battleState.isBattleOver)
                Text(
                  'Enemy turn...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[300],
                      ),
                ),
            ],
          ),
        ),

        // Enemy formation (top area)
        Expanded(
          flex: 3,
          child: Center(
            child: EnemyFormation(
              enemies: battleState.enemies,
              isSelectingTarget:
                  _currentMenuState == MenuState.targetEnemy,
              onEnemyTap: _onEnemyTap,
            ),
          ),
        ),

        // Battle log
        BattleLog(messages: battleState.battleLog),

        const SizedBox(height: 8),

        // Party status
        PartyStatusBar(
          party: battleState.party,
          activeHeroId: battleState.activeHeroId,
          isSelectingAlly: _currentMenuState == MenuState.targetAlly,
          onHeroTap: _onHeroTap,
        ),

        const SizedBox(height: 8),

        // Action menu (only when it's player's turn)
        if (isPlayerTurn && activeHero != null)
          ActionMenu(
            key: _actionMenuKey,
            activeHero: activeHero,
            skills: gameData.skills,
            items: gameData.items,
            inventory: battleState.inventory,
            onActionSelected: _onActionSelected,
            onMenuStateChanged: (state) {
              setState(() => _currentMenuState = state);
            },
          )
        else
          const SizedBox(height: 80), // Placeholder space when not player turn

        const SizedBox(height: 8),
      ],
    );
  }

  void _showVictoryDialog(BattleState battleState) {
    final result = battleState.result;
    if (result == null) return;

    // Apply XP and level ups
    final battleNotifier = ref.read(battleProvider.notifier);
    final currentParty = ref.read(partyProvider);
    final updatedParty = battleNotifier.applyVictoryRewards(currentParty);
    ref.read(partyProvider.notifier).applyBattleResult(updatedParty);

    // Add gold
    ref.read(goldProvider.notifier).state += result.totalGold;

    // Update inventory from battle state
    ref.read(inventoryProvider.notifier).updateInventory(battleState.inventory);

    // Mark encounter cleared
    ref.read(clearedEncountersProvider.notifier).state = {
      ...ref.read(clearedEncountersProvider),
      widget.encounter.id,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'VICTORY!',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'XP gained: ${result.totalXp}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Gold gained: ${result.totalGold}',
              style: const TextStyle(color: Colors.amber),
            ),
            const SizedBox(height: 12),
            ...updatedParty.map((hero) {
              final oldHero = currentParty.firstWhere((h) => h.id == hero.id);
              final leveledUp = hero.level > oldHero.level;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hero.name,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (leveledUp) ...[
                      const SizedBox(width: 8),
                      Text(
                        'LEVEL UP! Lv.${hero.level}',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showDefeatDialog() {
    // Heal party on defeat (mercy mechanic)
    ref.read(partyProvider.notifier).healAll();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'DEFEAT',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.heart_broken, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Your party was defeated...\nYour heroes have been healed.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Return', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFledDialog() {
    // Update inventory from battle
    final battleState = ref.read(battleProvider);
    ref.read(inventoryProvider.notifier).updateInventory(battleState.inventory);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'ESCAPED',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'You got away safely!',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
