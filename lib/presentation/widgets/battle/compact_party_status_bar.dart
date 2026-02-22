import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import '../../../data/models/equipment.dart';
import '../../../data/models/status_effect.dart';
import '../../../domain/equipment_system.dart';
import '../common/hp_bar.dart';
import '../common/mp_bar.dart';

class CompactPartyStatusBar extends StatelessWidget {
  final List<Character> party;
  final String? activeHeroId;
  final Map<String, Equipment> equipmentData;

  const CompactPartyStatusBar({
    super.key,
    required this.party,
    this.activeHeroId,
    this.equipmentData = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: party.map((hero) {
          final stats = equipmentData.isNotEmpty
              ? EquipmentSystem.computeEffectiveStats(hero, equipmentData)
              : hero.baseStats;
          final isActive = hero.id == activeHeroId;
          final hpPct = stats.maxHp > 0 ? hero.currentHp / stats.maxHp : 0.0;
          final mpPct = stats.maxMp > 0 ? hero.currentMp / stats.maxMp : 0.0;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive
                      ? Colors.yellow.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.1),
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hero.name,
                    style: TextStyle(
                      fontSize: 8,
                      color: hero.isAlive ? Colors.white : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  HpBar(percent: hpPct, height: 5),
                  const SizedBox(height: 1),
                  MpBar(percent: mpPct, height: 3),
                  if (hero.statusEffects.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Wrap(
                        spacing: 1,
                        children: hero.statusEffects.map((e) {
                          final (icon, color) = _statusIcon(e.type);
                          return Icon(icon, size: 8, color: color);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static (IconData, Color) _statusIcon(StatusEffectType type) {
    return switch (type) {
      StatusEffectType.poison => (Icons.science, Colors.green),
      StatusEffectType.burn => (Icons.local_fire_department, Colors.orange),
      StatusEffectType.stun => (Icons.flash_on, Colors.yellow),
      StatusEffectType.atkUp => (Icons.arrow_upward, Colors.red),
      StatusEffectType.atkDown => (Icons.arrow_downward, Colors.red),
      StatusEffectType.defUp => (Icons.arrow_upward, Colors.blue),
      StatusEffectType.defDown => (Icons.arrow_downward, Colors.blue),
    };
  }
}
