import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import '../../../data/models/equipment.dart';
import '../../../domain/equipment_system.dart';
import '../../animation/battle_animation_controller.dart';
import 'hero_status_card.dart';

class PartyStatusBar extends StatelessWidget {
  final List<Character> party;
  final String? activeHeroId;
  final bool isSelectingAlly;
  final void Function(String heroId)? onHeroTap;
  final Map<String, GlobalKey> targetKeys;
  final BattleAnimationController? animationController;
  final Map<String, Equipment> equipmentData;

  const PartyStatusBar({
    super.key,
    required this.party,
    this.activeHeroId,
    this.isSelectingAlly = false,
    this.onHeroTap,
    this.targetKeys = const {},
    this.animationController,
    this.equipmentData = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.2,
        ),
        itemCount: party.length,
        itemBuilder: (context, index) {
          final hero = party[index];
          return KeyedSubtree(
            key: targetKeys[hero.id] ?? ValueKey(hero.id),
            child: HeroStatusCard(
              hero: hero,
              isActive: hero.id == activeHeroId,
              isSelectable: isSelectingAlly && hero.isAlive,
              onTap: () => onHeroTap?.call(hero.id),
              animationController: animationController,
              effectiveStats: equipmentData.isNotEmpty
                  ? EquipmentSystem.computeEffectiveStats(hero, equipmentData)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
