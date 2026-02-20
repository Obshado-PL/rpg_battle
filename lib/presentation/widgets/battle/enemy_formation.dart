import 'package:flutter/material.dart';

import '../../../data/models/enemy.dart';
import 'enemy_sprite.dart';

class EnemyFormation extends StatelessWidget {
  final List<Enemy> enemies;
  final String? selectedTargetId;
  final bool isSelectingTarget;
  final void Function(String enemyId)? onEnemyTap;

  const EnemyFormation({
    super.key,
    required this.enemies,
    this.selectedTargetId,
    this.isSelectingTarget = false,
    this.onEnemyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: enemies.map((enemy) {
          return EnemySprite(
            enemy: enemy,
            isTargeted: enemy.id == selectedTargetId,
            isSelectable: isSelectingTarget && enemy.isAlive,
            onTap: enemy.isAlive ? () => onEnemyTap?.call(enemy.id) : null,
          );
        }).toList(),
      ),
    );
  }
}
