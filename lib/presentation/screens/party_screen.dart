import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/character.dart';
import '../providers/game_providers.dart';
import '../widgets/common/hero_portrait.dart';

class PartyScreen extends ConsumerWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = ref.watch(partyProvider);
    final roster = ref.watch(rosterProvider);

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
                      onPressed: () {
                        collectAndSave(ref);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PARTY',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.cyan,
                              ),
                    ),
                    const Spacer(),
                    Text(
                      '${party.length}/6',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                  ],
                ),
              ),

              // Active party section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Party',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildActivePartyGrid(context, ref, party),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bench section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Bench',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${roster.length})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Bench roster
              Expanded(
                child: roster.isEmpty
                    ? Center(
                        child: Text(
                          'No heroes on the bench',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white24,
                                  ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: roster.length,
                        itemBuilder: (context, index) {
                          final hero = roster[index];
                          return _buildHeroCard(
                            context,
                            ref,
                            hero,
                            isBench: true,
                            partySize: party.length,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePartyGrid(
      BuildContext context, WidgetRef ref, List<Character> party) {
    const maxSlots = 6;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: maxSlots,
      itemBuilder: (context, index) {
        if (index < party.length) {
          return _buildHeroCard(
            context,
            ref,
            party[index],
            isBench: false,
            partySize: party.length,
          );
        }
        // Empty slot
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white12, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    Character hero, {
    required bool isBench,
    required int partySize,
  }) {
    final rarityColor = _rarityBorderColor(hero);
    final classColor = _classColor(hero.heroClass);

    return GestureDetector(
      onTap: () {
        if (isBench) {
          // Move from bench to party (if party not full)
          if (partySize >= 6) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Party is full (max 6)'),
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }
          ref.read(rosterProvider.notifier).removeHero(hero.id);
          ref.read(partyProvider.notifier).updateParty(
            [...ref.read(partyProvider), hero],
          );
        } else {
          // Move from party to bench (min 1 hero)
          if (partySize <= 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Must keep at least 1 hero in party'),
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }
          final updatedParty =
              ref.read(partyProvider).where((h) => h.id != hero.id).toList();
          ref.read(partyProvider.notifier).updateParty(updatedParty);
          ref.read(rosterProvider.notifier).addHero(hero);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isBench
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: rarityColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroPortrait(
              spriteId: hero.spriteId,
              size: 40,
              borderColor: rarityColor,
            ),
            const SizedBox(height: 4),
            Text(
              hero.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: Colors.white,
                  ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: classColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'Lv.${hero.level}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 7,
                        color: Colors.white54,
                      ),
                ),
              ],
            ),
            Text(
              isBench ? 'Tap to add' : 'Tap to bench',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 6,
                    color: isBench ? Colors.cyan.withValues(alpha: 0.6) : Colors.white24,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rarityBorderColor(Character hero) {
    // We don't store rarity on Character, so use a simple heuristic
    // based on the hero's base stat total
    final total = hero.baseStats.maxHp +
        hero.baseStats.maxMp +
        hero.baseStats.attack +
        hero.baseStats.defense +
        hero.baseStats.magicAttack +
        hero.baseStats.magicDefense +
        hero.baseStats.speed;

    if (total > 350) return Colors.amber; // epic
    if (total > 280) return Colors.blue; // rare
    return Colors.white54; // common
  }

  Color _classColor(HeroClass heroClass) {
    return switch (heroClass) {
      HeroClass.warrior => Colors.orange,
      HeroClass.mage => Colors.purple,
      HeroClass.healer => Colors.green,
      HeroClass.rogue => Colors.amber,
    };
  }
}
