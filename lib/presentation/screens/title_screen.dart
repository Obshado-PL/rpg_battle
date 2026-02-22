import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/character.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/encounter.dart';
import '../../data/models/item.dart';
import '../../domain/sound_manager.dart';
import '../providers/game_providers.dart';
import '../widgets/common/hero_portrait.dart';
import 'battle_screen.dart';
import 'bestiary_screen.dart';
import 'equipment_screen.dart';
import 'gacha_screen.dart';
import 'party_screen.dart';
import 'shop_screen.dart';
import 'skill_tree_screen.dart';
import '../widgets/common/dialogue_overlay.dart';
import '../widgets/world_map/world_map_widget.dart';

class TitleScreen extends ConsumerWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameData = ref.watch(gameDataProvider);
    final gold = ref.watch(goldProvider);
    final clearedEncounters = ref.watch(clearedEncountersProvider);
    final party = ref.watch(partyProvider);
    final isMuted = ref.watch(soundMutedProvider);
    final soundManager = ref.watch(soundManagerProvider);
    final difficulty = ref.watch(difficultyProvider);

    // Play title BGM (no-op if already playing)
    soundManager.playBgm(BgmType.title);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Title
              Text(
                'RPG BATTLE',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.amber,
                      shadows: [
                        const Shadow(
                          color: Colors.amber,
                          blurRadius: 20,
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Turn-Based Combat',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      soundManager.toggleMute();
                      ref.read(soundMutedProvider.notifier).state =
                          soundManager.muted;
                    },
                    child: Icon(
                      isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Party summary
              _buildPartyPreview(context, party),

              // Gold display
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '$gold Gold',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.amber,
                          ),
                    ),
                  ],
                ),
              ),

              // Difficulty selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: Difficulty.values.map((d) {
                    final isSelected = d == difficulty;
                    final label = d.name[0].toUpperCase() + d.name.substring(1);
                    final color = switch (d) {
                      Difficulty.easy => Colors.green,
                      Difficulty.normal => Colors.amber,
                      Difficulty.hard => Colors.red,
                    };
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? Colors.white : Colors.white54,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: color.withValues(alpha: 0.6),
                        backgroundColor: Colors.grey[900],
                        side: BorderSide(
                          color: isSelected ? color : Colors.transparent,
                        ),
                        onSelected: (_) {
                          ref.read(difficultyProvider.notifier).state = d;
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // World map
              Expanded(
                child: WorldMapWidget(
                  encounters: gameData.encounters,
                  clearedEncounters: clearedEncounters,
                  onEncounterTap: (encounter) =>
                      _startBattle(context, ref, encounter),
                ),
              ),

              // Action buttons - Row 1
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ShopScreen()),
                            );
                          },
                          icon: const Icon(Icons.store, size: 14),
                          label: const Text('Shop', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EquipmentScreen()),
                            );
                          },
                          icon: const Icon(Icons.shield, size: 14),
                          label: const Text('Equip', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan[700],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SkillTreeScreen()),
                            );
                          },
                          icon: const Icon(Icons.account_tree, size: 14),
                          label: const Text('Skills', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[700],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons - Row 2
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BestiaryScreen()),
                            );
                          },
                          icon: const Icon(Icons.menu_book, size: 14),
                          label: const Text('Bestiary', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[700],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const GachaScreen()),
                            );
                          },
                          icon: const Icon(Icons.auto_awesome, size: 14),
                          label: const Text('Summon', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple[700],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PartyScreen()),
                            );
                          },
                          icon: const Icon(Icons.groups, size: 14),
                          label: const Text('Party', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[700],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons - Row 3
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(partyProvider.notifier).healAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Party fully healed!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite, size: 14),
                    label: const Text('Heal Party', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),

              // New Game button
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: TextButton.icon(
                  onPressed: () => _confirmNewGame(context, ref),
                  icon: const Icon(Icons.refresh, size: 12, color: Colors.white38),
                  label: Text(
                    'New Game',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmNewGame(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('New Game',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will erase all progress. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetGame(ref);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New game started!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetGame(WidgetRef ref) {
    final gameData = ref.read(gameDataProvider);
    // Reset all providers to defaults
    ref.read(partyProvider.notifier).updateParty(gameData.defaultParty);
    ref.read(rosterProvider.notifier).reset();
    ref.read(ownedHeroIdsProvider.notifier).reset();
    ref.read(inventoryProvider.notifier).updateInventory([
      const InventorySlot(itemId: 'potion', quantity: 5),
      const InventorySlot(itemId: 'hi_potion', quantity: 2),
      const InventorySlot(itemId: 'ether', quantity: 3),
      const InventorySlot(itemId: 'phoenix_down', quantity: 2),
    ]);
    ref.read(goldProvider.notifier).state = 100;
    ref.read(clearedEncountersProvider.notifier).state = {};
    // Reset owned equipment to starter set
    ref.read(ownedEquipmentProvider.notifier).reset();
    // Reset difficulty, bestiary, skill tree choices
    ref.read(difficultyProvider.notifier).state = Difficulty.normal;
    ref.read(bestiaryProvider.notifier).reset();
    ref.read(skillTreeChoicesProvider.notifier).reset();
    // Delete saved data
    ref.read(saveManagerProvider).deleteSave();
  }

  Widget _buildPartyPreview(BuildContext context, List<Character> party) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: party.map((hero) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroPortrait(spriteId: hero.spriteId, size: 36),
              const SizedBox(height: 4),
              Text(
                hero.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Lv.${hero.level}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                      fontSize: 7,
                    ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _startBattle(BuildContext context, WidgetRef ref, Encounter encounter) {
    final gameData = ref.read(gameDataProvider);
    final story = gameData.storyData[encounter.id];

    if (story != null && story.preBattle.isNotEmpty) {
      // Show pre-battle dialogue first
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        pageBuilder: (ctx, anim1, anim2) {
          return DialogueOverlay(
            lines: story.preBattle,
            onComplete: () {
              Navigator.of(ctx).pop();
              _navigateToBattle(context, encounter);
            },
          );
        },
      );
    } else {
      _navigateToBattle(context, encounter);
    }
  }

  void _navigateToBattle(BuildContext context, Encounter encounter) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BattleScreen(encounter: encounter),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
