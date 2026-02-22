import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/game_data.dart';
import '../../data/models/battle_action.dart';
import '../../data/models/battle_state.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/encounter.dart';
import '../../domain/battle_engine.dart';
import '../../domain/loot_system.dart';
import '../../domain/sound_manager.dart';
import '../widgets/common/dialogue_overlay.dart';
import '../../presentation/providers/game_providers.dart';
import '../animation/battle_animation_controller.dart';
import '../animation/vfx_overlay.dart';
import '../widgets/battle/action_menu.dart';
import '../widgets/battle/battle_log.dart';
import '../widgets/battle/enemy_formation.dart';
import '../widgets/battle/party_status_bar.dart';
import '../widgets/battle/battle_results_dialog.dart';
import '../widgets/battle/turn_order_bar.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final Encounter encounter;

  const BattleScreen({super.key, required this.encounter});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  final _actionMenuKey = GlobalKey<ActionMenuState>();
  MenuState _currentMenuState = MenuState.main;
  bool _battleStarted = false;
  bool _autoBattlePending = false;

  // Animation system
  late BattleAnimationController _animController;
  final Map<String, GlobalKey> _targetKeys = {};

  // Screen shake
  late AnimationController _screenShakeController;
  late Animation<double> _screenShakeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = BattleAnimationController();
    _animController.addListener(_onVfxChanged);

    // Screen shake controller
    _screenShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _screenShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 6), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -6, end: 5), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 5, end: -4), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -4, end: 3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 3, end: -2), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 15),
    ]).animate(_screenShakeController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBattle();
    });
  }

  void _onVfxChanged() {
    // Trigger screen shake when a screenShake command appears
    if (_animController.hasScreenCommand(VfxType.screenShake) &&
        !_screenShakeController.isAnimating) {
      _screenShakeController.forward(from: 0);
    }
  }

  void _initTargetKeys(BattleState battleState) {
    for (final enemy in battleState.enemies) {
      _targetKeys.putIfAbsent(enemy.id, () => GlobalKey());
    }
    for (final hero in battleState.party) {
      _targetKeys.putIfAbsent(hero.id, () => GlobalKey());
    }
  }

  void _startBattle() {
    final party = ref.read(partyProvider);
    final inventory = ref.read(inventoryProvider);
    final difficulty = ref.read(difficultyProvider);
    final notifier = ref.read(battleProvider.notifier);

    // Start battle BGM
    ref.read(soundManagerProvider).playBgm(BgmType.battle);

    // Wire up animation callback
    notifier.onPlayAnimations = _playAnimations;

    // Sync speed multiplier
    final speed = ref.read(battleSpeedProvider);
    notifier.speedMultiplier = speed;
    _animController.speedMultiplier = speed;

    notifier.startBattle(
      encounter: widget.encounter,
      party: party,
      inventory: inventory,
      difficulty: difficulty,
    );
    setState(() => _battleStarted = true);
  }

  void _cycleSpeed() {
    final current = ref.read(battleSpeedProvider);
    final next = switch (current) {
      1.0 => 0.5,
      0.5 => 0.33,
      _ => 1.0,
    };
    ref.read(battleSpeedProvider.notifier).state = next;
    ref.read(battleProvider.notifier).speedMultiplier = next;
    _animController.speedMultiplier = next;
  }

  String _speedLabel(double speed) {
    return switch (speed) {
      0.5 => '2x',
      0.33 => '3x',
      _ => '1x',
    };
  }

  void _toggleAutoBattle() {
    final current = ref.read(autoBattleProvider);
    ref.read(autoBattleProvider.notifier).state = !current;
    if (!current) {
      // Just turned on — trigger if it's already player turn
      _tryAutoBattle();
    }
  }

  void _tryAutoBattle() {
    if (_autoBattlePending) return;
    final autoBattle = ref.read(autoBattleProvider);
    if (!autoBattle) return;

    final battleState = ref.read(battleProvider);
    if (battleState.phase != BattlePhase.playerInput) return;

    final hero = battleState.currentHero;
    if (hero == null) return;

    // Find first alive enemy
    final target = battleState.enemies.where((e) => e.isAlive).firstOrNull;
    if (target == null) return;

    _autoBattlePending = true;
    // Small delay so UI renders before action fires
    Future.delayed(const Duration(milliseconds: 100), () {
      _autoBattlePending = false;
      if (!mounted) return;
      final action = BattleAction(
        actorId: hero.id,
        isHero: true,
        actionType: ActionType.attack,
        targetId: target.id,
      );
      _onActionSelected(action);
    });
  }

  Future<void> _playAnimations(List<BattleAnimationEvent> events) async {
    // Play sound effects based on event types
    final sound = ref.read(soundManagerProvider);
    for (final event in events) {
      switch (event.type) {
        case 'attack':
        case 'damage':
          if (event.isCritical) {
            sound.playSfx(SfxType.criticalHit);
          } else {
            sound.playSfx(SfxType.attackHit);
          }
        case 'skill':
          sound.playSfx(SfxType.magicCast);
        case 'heal':
          sound.playSfx(SfxType.heal);
        case 'miss':
          sound.playSfx(SfxType.miss);
        case 'defend':
          sound.playSfx(SfxType.defend);
        case 'death':
          // Determine if hero or enemy died
          final isHero = ref.read(battleProvider).party.any((h) => h.id == event.actorId);
          sound.playSfx(isHero ? SfxType.heroDeath : SfxType.enemyDeath);
      }
    }
    await _animController.playSequence(events);
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
  void dispose() {
    // Detach callback to avoid calling disposed controller
    ref.read(battleProvider.notifier).onPlayAnimations = null;
    _animController.removeListener(_onVfxChanged);
    _animController.dispose();
    _screenShakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleProvider);
    final gameData = ref.watch(gameDataProvider);
    final gradStart =
        Color(int.parse(widget.encounter.backgroundGradientStart));
    final gradEnd = Color(int.parse(widget.encounter.backgroundGradientEnd));

    // Ensure target keys exist for all actors
    _initTargetKeys(battleState);

    // Listen for battle end and auto-battle trigger
    ref.listen<BattleState>(battleProvider, (prev, next) {
      if (next.phase == BattlePhase.victory) {
        _showVictoryDialog(next);
      } else if (next.phase == BattlePhase.defeat) {
        _showDefeatDialog();
      } else if (next.phase == BattlePhase.fled) {
        _showFledDialog();
      } else if (next.phase == BattlePhase.playerInput) {
        _tryAutoBattle();
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
    final speed = ref.watch(battleSpeedProvider);
    final autoBattle = ref.watch(autoBattleProvider);

    return Stack(
      children: [
        // Main battle UI with screen shake
        AnimatedBuilder(
          animation: _screenShakeController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_screenShakeAnimation.value, 0),
              child: child,
            );
          },
          child: Column(
            children: [
              // Turn order bar
              TurnOrderBar(
                turnOrder: battleState.turnOrder,
                currentTurnIndex: battleState.currentTurnIndex,
                party: battleState.party,
                enemies: battleState.enemies,
              ),

              // Round indicator + speed/auto controls
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Round ${battleState.roundNumber}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    if (isPlayerTurn && activeHero != null)
                      Expanded(
                        child: Text(
                          '${activeHero.name}\'s turn',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.yellow,
                              ),
                        ),
                      ),
                    if (!isPlayerTurn && !battleState.isBattleOver)
                      Expanded(
                        child: Text(
                          'Enemy turn...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red[300],
                              ),
                        ),
                      ),
                    if (isPlayerTurn || battleState.isBattleOver)
                      const Spacer(),
                    // Speed toggle
                    GestureDetector(
                      onTap: _cycleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: speed < 1.0
                              ? Colors.orange.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: speed < 1.0
                                ? Colors.orange.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _speedLabel(speed),
                          style: TextStyle(
                            color: speed < 1.0 ? Colors.orange : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Auto-battle toggle
                    GestureDetector(
                      onTap: _toggleAutoBattle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: autoBattle
                              ? Colors.cyan.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: autoBattle
                                ? Colors.cyan.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'AUTO',
                          style: TextStyle(
                            color: autoBattle ? Colors.cyan : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                    targetKeys: _targetKeys,
                    animationController: _animController,
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
                targetKeys: _targetKeys,
                animationController: _animController,
                equipmentData: gameData.equipment,
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
                const SizedBox(
                    height: 80), // Placeholder space when not player turn

              const SizedBox(height: 8),
            ],
          ),
        ),

        // VFX overlay (damage numbers, skill effects, screen flash)
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: BattleVfxOverlay(
              animationController: _animController,
              targetKeys: _targetKeys,
            ),
          ),
        ),
      ],
    );
  }

  void _showVictoryDialog(BattleState battleState) {
    final result = battleState.result;
    if (result == null) return;

    final sound = ref.read(soundManagerProvider);
    sound.stopBgm();
    sound.playSfx(SfxType.victory);

    // Apply XP and level ups
    final battleNotifier = ref.read(battleProvider.notifier);
    final currentParty = ref.read(partyProvider);
    final updatedParty = battleNotifier.applyVictoryRewards(currentParty);
    ref.read(partyProvider.notifier).applyBattleResult(updatedParty);

    // Add gold
    ref.read(goldProvider.notifier).state += result.totalGold;

    // Update inventory from battle state
    ref
        .read(inventoryProvider.notifier)
        .updateInventory(battleState.inventory);

    // Roll loot drops
    final gameData = ref.read(gameDataProvider);
    final difficulty = ref.read(difficultyProvider);
    final diffConfig = DifficultyConfig.get(difficulty);
    final lootTable =
        gameData.getLootTableForEncounter(widget.encounter);
    final ownedEquipment = ref.read(ownedEquipmentProvider);
    final lootResult = LootSystem().rollLoot(
      lootTable: lootTable,
      ownedEquipment: ownedEquipment,
      rewardScale: diffConfig.rewardScale,
    );

    // Add loot items to inventory
    for (final itemLoot in lootResult.items) {
      ref
          .read(inventoryProvider.notifier)
          .addItem(itemLoot.itemId, itemLoot.quantity);
    }

    // Add loot equipment to owned
    if (lootResult.equipmentIds.isNotEmpty) {
      ref
          .read(ownedEquipmentProvider.notifier)
          .addAll(lootResult.equipmentIds);
    }

    // Record bestiary defeats
    ref
        .read(bestiaryProvider.notifier)
        .recordDefeats(widget.encounter.enemyIds);

    // Mark encounter cleared
    ref.read(clearedEncountersProvider.notifier).state = {
      ...ref.read(clearedEncountersProvider),
      widget.encounter.id,
    };

    // Auto-save after victory
    collectAndSave(ref);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (ctx, anim1, anim2) => BattleResultsDialog(
        xpGained: result.totalXp,
        goldGained: result.totalGold,
        updatedParty: updatedParty,
        previousParty: currentParty,
        lootResult: lootResult,
        gameData: gameData,
        onContinue: () {
          Navigator.of(ctx).pop();
          _showPostBattleDialogue();
        },
      ),
    );
  }

  void _showPostBattleDialogue() {
    final gameData = ref.read(gameDataProvider);
    final story = gameData.storyData[widget.encounter.id];

    if (story != null && story.postBattle.isNotEmpty) {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        pageBuilder: (ctx, anim1, anim2) {
          return DialogueOverlay(
            lines: story.postBattle,
            onComplete: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          );
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showDefeatDialog() {
    final sound = ref.read(soundManagerProvider);
    sound.stopBgm();
    sound.playSfx(SfxType.defeat);

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
    ref
        .read(inventoryProvider.notifier)
        .updateInventory(battleState.inventory);

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
            child:
                const Text('Continue', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
