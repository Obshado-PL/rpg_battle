import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/game_data.dart';
import '../../data/models/character.dart';
import '../../data/models/equipment.dart';
import '../../data/models/item.dart';
import '../providers/game_providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameData = ref.watch(gameDataProvider);
    final gold = ref.watch(goldProvider);
    final owned = ref.watch(ownedEquipmentProvider);

    // Split equipment into buyable (price > 0) and already owned
    final buyableEquipment = gameData.equipment.values
        .where((eq) => eq.price > 0)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));

    // Buyable items (if they have prices)
    final buyableItems = gameData.items.values
        .where((item) => item.price > 0)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F23),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SHOP',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.amber,
                              ),
                    ),
                    const Spacer(),
                    const Icon(Icons.monetization_on,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '$gold',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.amber,
                          ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                        tabs: const [
                          Tab(text: 'EQUIPMENT'),
                          Tab(text: 'ITEMS'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildEquipmentTab(
                                context, ref, buyableEquipment, gold, owned),
                            _buildItemsTab(
                                context, ref, buyableItems, gold, gameData),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentTab(BuildContext context, WidgetRef ref,
      List<Equipment> equipment, int gold, Set<String> owned) {
    if (equipment.isEmpty) {
      return const Center(
        child: Text('No equipment for sale', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: equipment.length,
      itemBuilder: (context, index) {
        final eq = equipment[index];
        final alreadyOwned = owned.contains(eq.id);
        final canAfford = gold >= eq.price;

        return _EquipmentShopTile(
          eq: eq,
          alreadyOwned: alreadyOwned,
          canAfford: canAfford,
          onBuy: () {
            ref.read(goldProvider.notifier).state -= eq.price;
            ref.read(ownedEquipmentProvider.notifier).add(eq.id);
            collectAndSave(ref);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bought ${eq.name}!'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemsTab(BuildContext context, WidgetRef ref,
      List<Item> items, int gold, GameData gameData) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items for sale', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final canAfford = gold >= item.price;

        return _ItemShopTile(
          item: item,
          canAfford: canAfford,
          onBuy: () {
            ref.read(goldProvider.notifier).state -= item.price;
            ref.read(inventoryProvider.notifier).addItem(item.id);
            collectAndSave(ref);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bought ${item.name}!'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }
}

class _EquipmentShopTile extends StatelessWidget {
  final Equipment eq;
  final bool alreadyOwned;
  final bool canAfford;
  final VoidCallback onBuy;

  const _EquipmentShopTile({
    required this.eq,
    required this.alreadyOwned,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotIcon = switch (eq.slotType) {
      EquipmentSlotType.weapon => Icons.gavel,
      EquipmentSlotType.armor => Icons.shield,
      EquipmentSlotType.accessory => Icons.star,
    };

    final slotColor = switch (eq.slotType) {
      EquipmentSlotType.weapon => Colors.red[300]!,
      EquipmentSlotType.armor => Colors.blue[300]!,
      EquipmentSlotType.accessory => Colors.purple[300]!,
    };

    // Build bonus text
    final bonuses = <String>[];
    final s = eq.statBonuses;
    if (s.attack > 0) bonuses.add('ATK+${s.attack}');
    if (s.defense > 0) bonuses.add('DEF+${s.defense}');
    if (s.magicAttack > 0) bonuses.add('MAG+${s.magicAttack}');
    if (s.magicDefense > 0) bonuses.add('MDF+${s.magicDefense}');
    if (s.speed > 0) bonuses.add('SPD+${s.speed}');
    if (s.speed < 0) bonuses.add('SPD${s.speed}');
    if (s.maxHp > 0) bonuses.add('HP+${s.maxHp}');
    if (s.maxMp > 0) bonuses.add('MP+${s.maxMp}');

    // Usable by text
    final classes = eq.usableBy.map((c) {
      return switch (c) {
        HeroClass.warrior => 'WAR',
        HeroClass.mage => 'MAG',
        HeroClass.healer => 'HLR',
        HeroClass.rogue => 'ROG',
      };
    }).join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: alreadyOwned
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(slotIcon, color: slotColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eq.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(bonuses.join('  '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.greenAccent, fontSize: 7)),
                  const SizedBox(height: 2),
                  Text(classes,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white38, fontSize: 6)),
                ],
              ),
            ),
            if (alreadyOwned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('OWNED',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.green, fontSize: 7)),
              )
            else
              GestureDetector(
                onTap: canAfford ? onBuy : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? Colors.amber.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: canAfford
                          ? Colors.amber.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on,
                          size: 10,
                          color: canAfford ? Colors.amber : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${eq.price}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: canAfford ? Colors.amber : Colors.grey,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemShopTile extends StatelessWidget {
  final Item item;
  final bool canAfford;
  final VoidCallback onBuy;

  const _ItemShopTile({
    required this.item,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectText = switch (item.effect) {
      ItemEffect.restoreHp => 'Restore ${item.power} HP',
      ItemEffect.restoreMp => 'Restore ${item.power} MP',
      ItemEffect.revive => 'Revive with ${item.power}% HP',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2, color: Colors.tealAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(effectText,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white54, fontSize: 7)),
                ],
              ),
            ),
            GestureDetector(
              onTap: canAfford ? onBuy : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: canAfford
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: canAfford
                        ? Colors.amber.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on,
                        size: 10,
                        color: canAfford ? Colors.amber : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: canAfford ? Colors.amber : Colors.grey,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
