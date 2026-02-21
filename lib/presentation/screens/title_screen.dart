import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/game_data.dart';
import '../../data/models/character.dart';
import '../../data/models/encounter.dart';
import '../../data/models/item.dart';
import '../../domain/sound_manager.dart';
import '../providers/game_providers.dart';
import 'battle_screen.dart';
import 'equipment_screen.dart';
import 'shop_screen.dart';

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

              const SizedBox(height: 8),

              // Encounter list
              Expanded(
                child: _buildEncounterList(
                    context, ref, gameData, clearedEncounters),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ShopScreen()),
                            );
                          },
                          icon: const Icon(Icons.store, size: 14),
                          label: const Text('Shop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EquipmentScreen()),
                            );
                          },
                          icon: const Icon(Icons.shield, size: 14),
                          label: const Text('Equip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan[700],
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
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
                          label: const Text('Heal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
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
    // Delete saved data
    ref.read(saveManagerProvider).deleteSave();
  }

  Widget _buildPartyPreview(BuildContext context, List<Character> party) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: party.map((hero) {
          Color classColor;
          IconData classIcon;
          switch (hero.heroClass) {
            case HeroClass.warrior:
              classColor = Colors.orange;
              classIcon = Icons.security;
            case HeroClass.mage:
              classColor = Colors.purple;
              classIcon = Icons.auto_fix_high;
            case HeroClass.healer:
              classColor = Colors.green;
              classIcon = Icons.favorite;
            case HeroClass.rogue:
              classColor = Colors.amber;
              classIcon = Icons.flash_on;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: classColor.withValues(alpha: 0.3),
                child: Icon(classIcon, color: classColor, size: 20),
              ),
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

  Widget _buildEncounterList(
    BuildContext context,
    WidgetRef ref,
    GameData gameData,
    Set<String> clearedEncounters,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: gameData.encounters.length,
      itemBuilder: (context, index) {
        final encounter = gameData.encounters[index];
        final isCleared = clearedEncounters.contains(encounter.id);
        final prevCleared =
            index == 0 || clearedEncounters.contains(gameData.encounters[index - 1].id);
        final isLocked = !prevCleared && !isCleared;

        final gradStart =
            Color(int.parse(encounter.backgroundGradientStart));

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isLocked
                ? Colors.grey[900]
                : gradStart.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isLocked
                  ? null
                  : () => _startBattle(context, encounter),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCleared
                        ? Colors.green.withValues(alpha: 0.5)
                        : isLocked
                            ? Colors.grey.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    // Encounter number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCleared
                            ? Colors.green
                            : isLocked
                                ? Colors.grey[800]
                                : gradStart,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCleared
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : isLocked
                                ? const Icon(Icons.lock,
                                    size: 14, color: Colors.grey)
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            encounter.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isLocked
                                      ? Colors.grey
                                      : Colors.white,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${encounter.enemyIds.length} enemies  |  Difficulty ${encounter.difficulty}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isLocked
                                      ? Colors.grey[700]
                                      : Colors.white54,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    if (!isLocked)
                      Icon(
                        Icons.play_arrow,
                        color: isCleared ? Colors.green : Colors.white54,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startBattle(BuildContext context, Encounter encounter) {
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
