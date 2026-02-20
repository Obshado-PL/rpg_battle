import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import '../common/hp_bar.dart';
import '../common/mp_bar.dart';

class HeroStatusCard extends StatelessWidget {
  final Character hero;
  final bool isActive;
  final bool isSelectable;
  final VoidCallback? onTap;

  const HeroStatusCard({
    super.key,
    required this.hero,
    this.isActive = false,
    this.isSelectable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isSelectable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hero.isAlive
              ? (isActive
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05))
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : isSelectable
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _classIcon(),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hero.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hero.isAlive ? Colors.white : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hero.isDefending)
                  const Icon(Icons.shield, size: 12, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 4),
            HpBar(
              percent: hero.hpPercent,
              height: 6,
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Text(
                  '${hero.currentHp}/${hero.baseStats.maxHp}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 7),
                ),
              ],
            ),
            const SizedBox(height: 2),
            MpBar(
              percent: hero.mpPercent,
              height: 4,
            ),
            Row(
              children: [
                Text(
                  '${hero.currentMp}/${hero.baseStats.maxMp}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 7,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _classIcon() {
    IconData iconData;
    Color iconColor;
    switch (hero.heroClass) {
      case HeroClass.warrior:
        iconData = Icons.security;
        iconColor = Colors.orange;
        break;
      case HeroClass.mage:
        iconData = Icons.auto_fix_high;
        iconColor = Colors.purple;
        break;
      case HeroClass.healer:
        iconData = Icons.favorite;
        iconColor = Colors.green;
        break;
      case HeroClass.rogue:
        iconData = Icons.flash_on;
        iconColor = Colors.amber;
        break;
    }
    return Icon(iconData, size: 12, color: iconColor);
  }
}
