import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import '../../../data/models/equipment.dart';
import '../../../domain/equipment_system.dart';
import '../../animation/battle_animation_controller.dart';
import 'battle_hero_sprite.dart';

class HeroFormation extends StatelessWidget {
  final List<Character> party;
  final String? activeHeroId;
  final bool isSelectingAlly;
  final void Function(String heroId)? onHeroTap;
  final Map<String, GlobalKey> targetKeys;
  final BattleAnimationController? animationController;
  final Map<String, Equipment> equipmentData;

  const HeroFormation({
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: party.map((hero) {
          return KeyedSubtree(
            key: targetKeys[hero.id] ?? ValueKey(hero.id),
            child: BattleHeroSprite(
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
        }).toList(),
      ),
    );
  }
}
