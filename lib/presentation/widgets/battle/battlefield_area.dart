import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import '../../../data/models/enemy.dart';
import '../../../data/models/equipment.dart';
import '../../animation/battle_animation_controller.dart';
import 'enemy_formation.dart';
import 'hero_formation.dart';

class BattlefieldArea extends StatelessWidget {
  final List<Character> party;
  final List<Enemy> enemies;
  final String? activeHeroId;
  final bool isSelectingTarget;
  final bool isSelectingAlly;
  final void Function(String enemyId)? onEnemyTap;
  final void Function(String heroId)? onHeroTap;
  final Map<String, GlobalKey> targetKeys;
  final BattleAnimationController? animationController;
  final Map<String, Equipment> equipmentData;

  const BattlefieldArea({
    super.key,
    required this.party,
    required this.enemies,
    this.activeHeroId,
    this.isSelectingTarget = false,
    this.isSelectingAlly = false,
    this.onEnemyTap,
    this.onHeroTap,
    this.targetKeys = const {},
    this.animationController,
    this.equipmentData = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left side: Hero formation (bottom-aligned)
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: HeroFormation(
                party: party,
                activeHeroId: activeHeroId,
                isSelectingAlly: isSelectingAlly,
                onHeroTap: onHeroTap,
                targetKeys: targetKeys,
                animationController: animationController,
                equipmentData: equipmentData,
              ),
            ),
          ),
          // Right side: Enemy formation (top-aligned)
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: EnemyFormation(
                enemies: enemies,
                isSelectingTarget: isSelectingTarget,
                onEnemyTap: onEnemyTap,
                targetKeys: targetKeys,
                animationController: animationController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
