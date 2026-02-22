import 'package:flutter/material.dart';

import '../../../data/datasources/game_data.dart';
import '../../../data/models/character.dart';
import '../../../domain/loot_system.dart';

class BattleResultsDialog extends StatefulWidget {
  final int xpGained;
  final int goldGained;
  final List<Character> updatedParty;
  final List<Character> previousParty;
  final LootResult lootResult;
  final GameData gameData;
  final VoidCallback onContinue;

  const BattleResultsDialog({
    super.key,
    required this.xpGained,
    required this.goldGained,
    required this.updatedParty,
    required this.previousParty,
    required this.lootResult,
    required this.gameData,
    required this.onContinue,
  });

  @override
  State<BattleResultsDialog> createState() => _BattleResultsDialogState();
}

class _BattleResultsDialogState extends State<BattleResultsDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _sectionAnims;

  @override
  void initState() {
    super.initState();
    // 5 sections: header, xp/gold, heroes, loot, button
    const sectionCount = 5;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sectionAnims = List.generate(sectionCount, (i) {
      final start = i / sectionCount;
      final end = (i + 1) / sectionCount;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Section 0: Header
                FadeTransition(
                  opacity: _sectionAnims[0],
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events,
                          size: 48, color: Colors.amber),
                      const SizedBox(height: 8),
                      const Text(
                        'VICTORY!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Section 1: XP and Gold
                FadeTransition(
                  opacity: _sectionAnims[1],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _rewardChip(
                          Icons.star, '${widget.xpGained} XP', Colors.cyan),
                      _rewardChip(Icons.monetization_on,
                          '${widget.goldGained} Gold', Colors.amber),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),

                // Section 2: Hero results
                FadeTransition(
                  opacity: _sectionAnims[2],
                  child: Column(
                    children: widget.updatedParty.map((hero) {
                      final oldHero = widget.previousParty
                          .firstWhere((h) => h.id == hero.id);
                      final leveledUp = hero.level > oldHero.level;
                      return _heroResultRow(hero, oldHero, leveledUp);
                    }).toList(),
                  ),
                ),

                // Section 3: Loot
                if (!widget.lootResult.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _sectionAnims[3],
                    child: _buildLootSection(),
                  ),
                ],

                const SizedBox(height: 16),

                // Section 4: Continue button
                FadeTransition(
                  opacity: _sectionAnims[4],
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.withValues(alpha: 0.2),
                        foregroundColor: Colors.amber,
                        side: const BorderSide(color: Colors.amber),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rewardChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _heroResultRow(
      Character hero, Character oldHero, bool leveledUp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Name
          Expanded(
            child: Text(
              hero.name,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          // Level
          Text(
            'Lv.${hero.level}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (leveledUp) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.yellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: Colors.yellow.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'LEVEL UP!',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLootSection() {
    return Column(
      children: [
        const Text(
          'Loot Drops',
          style: TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        ...widget.lootResult.items.map((loot) {
          final item = widget.gameData.items[loot.itemId];
          final name = item?.name ?? loot.itemId;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2,
                    size: 14, color: Colors.tealAccent),
                const SizedBox(width: 6),
                Text(
                  '$name x${loot.quantity}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }),
        ...widget.lootResult.equipmentIds.map((eqId) {
          final eq = widget.gameData.equipment[eqId];
          final name = eq?.name ?? eqId;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield,
                    size: 14, color: Colors.orangeAccent),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'NEW!',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
