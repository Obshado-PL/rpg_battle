import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import 'hero_status_card.dart';

class PartyStatusBar extends StatelessWidget {
  final List<Character> party;
  final String? activeHeroId;
  final bool isSelectingAlly;
  final void Function(String heroId)? onHeroTap;

  const PartyStatusBar({
    super.key,
    required this.party,
    this.activeHeroId,
    this.isSelectingAlly = false,
    this.onHeroTap,
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
          return HeroStatusCard(
            hero: hero,
            isActive: hero.id == activeHeroId,
            isSelectable: isSelectingAlly && hero.isAlive,
            onTap: () => onHeroTap?.call(hero.id),
          );
        },
      ),
    );
  }
}
