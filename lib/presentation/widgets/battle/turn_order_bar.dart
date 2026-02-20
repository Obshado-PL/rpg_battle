import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import '../../../data/models/enemy.dart';

class TurnOrderBar extends StatelessWidget {
  final List<String> turnOrder;
  final int currentTurnIndex;
  final List<Character> party;
  final List<Enemy> enemies;

  const TurnOrderBar({
    super.key,
    required this.turnOrder,
    required this.currentTurnIndex,
    required this.party,
    required this.enemies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: turnOrder.length,
        itemBuilder: (context, index) {
          final actorId = turnOrder[index];
          final isCurrent = index == currentTurnIndex;
          final isHero = party.any((h) => h.id == actorId);

          Color color;
          IconData icon;
          bool isAlive;

          if (isHero) {
            final hero = party.firstWhere((h) => h.id == actorId);
            isAlive = hero.isAlive;
            switch (hero.heroClass) {
              case HeroClass.warrior:
                color = Colors.orange;
                icon = Icons.security;
                break;
              case HeroClass.mage:
                color = Colors.purple;
                icon = Icons.auto_fix_high;
                break;
              case HeroClass.healer:
                color = Colors.green;
                icon = Icons.favorite;
                break;
              case HeroClass.rogue:
                color = Colors.amber;
                icon = Icons.flash_on;
                break;
            }
          } else {
            final enemy = enemies.firstWhere((e) => e.id == actorId);
            color = Color(int.parse(enemy.spriteColor));
            icon = Icons.dangerous;
            isAlive = enemy.isAlive;
          }

          if (!isAlive) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 36 : 30,
              height: isCurrent ? 36 : 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isCurrent ? 0.9 : 0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? Colors.white : Colors.transparent,
                  width: isCurrent ? 2 : 0,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: isCurrent ? 18 : 14,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
