import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/game_data.dart';
import '../../data/models/character.dart';
import '../../data/models/equipment.dart';
import '../../data/models/stats.dart';
import '../../domain/equipment_system.dart';
import '../providers/game_providers.dart';
import '../widgets/common/hero_portrait.dart';

class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  int _selectedHeroIndex = 0;

  @override
  Widget build(BuildContext context) {
    final party = ref.watch(partyProvider);
    final gameData = ref.watch(gameDataProvider);
    final owned = ref.watch(ownedEquipmentProvider);
    final hero = party[_selectedHeroIndex];
    final effectiveStats =
        EquipmentSystem.computeEffectiveStats(hero, gameData.equipment);

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
                      'EQUIP',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.cyan,
                              ),
                    ),
                  ],
                ),
              ),

              // Hero selector
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: party.length,
                  itemBuilder: (context, index) {
                    final h = party[index];
                    final isSelected = index == _selectedHeroIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedHeroIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? _heroClassColor(h.heroClass)
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HeroPortrait(spriteId: h.spriteId, size: 24),
                            const SizedBox(height: 4),
                            Text(h.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 7)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Stats display
              _buildStatsPanel(context, hero, effectiveStats),

              const SizedBox(height: 12),

              // Equipment slots
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSlot(
                      context,
                      ref,
                      hero,
                      EquipmentSlotType.weapon,
                      hero.weaponId,
                      gameData,
                      owned,
                    ),
                    const SizedBox(height: 8),
                    _buildSlot(
                      context,
                      ref,
                      hero,
                      EquipmentSlotType.armor,
                      hero.armorId,
                      gameData,
                      owned,
                    ),
                    const SizedBox(height: 8),
                    _buildSlot(
                      context,
                      ref,
                      hero,
                      EquipmentSlotType.accessory,
                      hero.accessoryId,
                      gameData,
                      owned,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPanel(
      BuildContext context, Character hero, Stats effective) {
    final base = hero.baseStats;
    final theme = Theme.of(context);

    Widget statRow(String label, int baseVal, int effVal) {
      final diff = effVal - baseVal;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white54, fontSize: 7)),
            ),
            SizedBox(
              width: 24,
              child: Text('$effVal',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 7),
                  textAlign: TextAlign.right),
            ),
            const SizedBox(width: 4),
            if (diff != 0)
              Text(
                diff > 0 ? '(+$diff)' : '($diff)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: diff > 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 6,
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Left column
          Expanded(
            child: Column(
              children: [
                statRow('HP', base.maxHp, effective.maxHp),
                statRow('MP', base.maxMp, effective.maxMp),
                statRow('ATK', base.attack, effective.attack),
                statRow('DEF', base.defense, effective.defense),
              ],
            ),
          ),
          // Right column
          Expanded(
            child: Column(
              children: [
                statRow('MAG', base.magicAttack, effective.magicAttack),
                statRow('MDF', base.magicDefense, effective.magicDefense),
                statRow('SPD', base.speed, effective.speed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(
    BuildContext context,
    WidgetRef ref,
    Character hero,
    EquipmentSlotType slotType,
    String? currentEqId,
    GameData gameData,
    Set<String> owned,
  ) {
    final theme = Theme.of(context);
    final currentEq =
        currentEqId != null ? gameData.equipment[currentEqId] : null;

    final slotLabel = switch (slotType) {
      EquipmentSlotType.weapon => 'WEAPON',
      EquipmentSlotType.armor => 'ARMOR',
      EquipmentSlotType.accessory => 'ACCESSORY',
    };

    final slotIcon = switch (slotType) {
      EquipmentSlotType.weapon => Icons.gavel,
      EquipmentSlotType.armor => Icons.shield,
      EquipmentSlotType.accessory => Icons.star,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(slotIcon, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(slotLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white54, fontSize: 7)),
              const Spacer(),
              if (currentEq != null)
                GestureDetector(
                  onTap: () {
                    ref
                        .read(partyProvider.notifier)
                        .unequip(hero.id, slotType);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('REMOVE',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.red[300], fontSize: 6)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (currentEq != null)
            Text(currentEq.name,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.white))
          else
            Text('- Empty -',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.white24, fontSize: 7)),
          const Divider(color: Colors.white12, height: 16),
          // Available equipment for this slot
          ..._buildAvailableEquipment(
              context, ref, hero, slotType, currentEqId, gameData, owned),
        ],
      ),
    );
  }

  List<Widget> _buildAvailableEquipment(
    BuildContext context,
    WidgetRef ref,
    Character hero,
    EquipmentSlotType slotType,
    String? currentEqId,
    GameData gameData,
    Set<String> owned,
  ) {
    final theme = Theme.of(context);

    // Get all owned equipment of this slot type that this hero can use
    final available = owned
        .map((id) => gameData.equipment[id])
        .where((eq) =>
            eq != null &&
            eq.slotType == slotType &&
            eq.usableBy.contains(hero.heroClass) &&
            eq.id != currentEqId)
        .cast<Equipment>()
        .toList()
      ..sort((a, b) => b.price.compareTo(a.price));

    if (available.isEmpty) {
      return [
        Text('No other equipment available',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.white24, fontSize: 6)),
      ];
    }

    final currentStats =
        EquipmentSystem.computeEffectiveStats(hero, gameData.equipment);

    return available.map((eq) {
      final hypothetical =
          EquipmentSystem.computeStatsWithSwap(hero, gameData.equipment, eq);

      Widget diffChip(String label, int curr, int hyp) {
        final d = hyp - curr;
        if (d == 0) return const SizedBox.shrink();
        return Text(
          '$label${d > 0 ? "+$d" : "$d"}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: d > 0 ? Colors.greenAccent : Colors.redAccent,
            fontSize: 6,
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: GestureDetector(
          onTap: () {
            ref.read(partyProvider.notifier).equip(hero.id, eq);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eq.name,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white, fontSize: 8)),
                      Wrap(
                        spacing: 6,
                        children: [
                          diffChip('HP', currentStats.maxHp, hypothetical.maxHp),
                          diffChip('MP', currentStats.maxMp, hypothetical.maxMp),
                          diffChip('ATK', currentStats.attack, hypothetical.attack),
                          diffChip('DEF', currentStats.defense, hypothetical.defense),
                          diffChip('MAG', currentStats.magicAttack, hypothetical.magicAttack),
                          diffChip('MDF', currentStats.magicDefense, hypothetical.magicDefense),
                          diffChip('SPD', currentStats.speed, hypothetical.speed),
                        ],
                      ),
                    ],
                  ),
                ),
                Text('EQUIP',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.cyan, fontSize: 7)),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _heroClassColor(HeroClass heroClass) {
    return switch (heroClass) {
      HeroClass.warrior => Colors.orange,
      HeroClass.mage => Colors.purple,
      HeroClass.healer => Colors.green,
      HeroClass.rogue => Colors.amber,
    };
  }

}
