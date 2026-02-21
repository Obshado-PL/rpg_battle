import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enemy.dart';
import '../providers/game_providers.dart';

class BestiaryScreen extends ConsumerWidget {
  const BestiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameData = ref.watch(gameDataProvider);
    final bestiaryDefeats = ref.watch(bestiaryProvider);
    final allEnemies = gameData.enemyTemplates.values.toList();

    final discovered =
        allEnemies.where((e) => bestiaryDefeats.containsKey(e.id)).length;

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
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.menu_book, color: Colors.tealAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Bestiary',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.tealAccent,
                              ),
                    ),
                    const Spacer(),
                    Text(
                      '$discovered / ${allEnemies.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                  ],
                ),
              ),

              // Enemy grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: allEnemies.length,
                  itemBuilder: (context, index) {
                    final enemy = allEnemies[index];
                    final defeats = bestiaryDefeats[enemy.id] ?? 0;
                    final isDiscovered = defeats > 0;

                    return _BestiaryCard(
                      enemy: enemy,
                      defeats: defeats,
                      isDiscovered: isDiscovered,
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
}

class _BestiaryCard extends StatelessWidget {
  final Enemy enemy;
  final int defeats;
  final bool isDiscovered;

  const _BestiaryCard({
    required this.enemy,
    required this.defeats,
    required this.isDiscovered,
  });

  @override
  Widget build(BuildContext context) {
    final spriteColor = Color(int.parse(enemy.spriteColor));

    if (!isDiscovered) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              '???',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: spriteColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: spriteColor.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enemy icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: spriteColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: spriteColor, width: 2),
              ),
              child: Icon(
                _enemyIcon(enemy.behavior),
                color: spriteColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              enemy.name,
              style: TextStyle(
                color: spriteColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'HP: ${enemy.stats.maxHp}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              'Defeated: $defeats',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final spriteColor = Color(int.parse(enemy.spriteColor));
    final s = enemy.stats;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          enemy.name,
          style: TextStyle(color: spriteColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: spriteColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: spriteColor, width: 2),
              ),
              child: Icon(
                _enemyIcon(enemy.behavior),
                color: spriteColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            _statRow('HP', s.maxHp, Colors.red),
            _statRow('MP', s.maxMp, Colors.blue),
            _statRow('ATK', s.attack, Colors.orange),
            _statRow('DEF', s.defense, Colors.cyan),
            _statRow('M.ATK', s.magicAttack, Colors.purple),
            _statRow('M.DEF', s.magicDefense, Colors.indigo),
            _statRow('SPD', s.speed, Colors.yellow),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('XP Reward: ${enemy.xpReward}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Gold: ${enemy.goldReward}',
                    style:
                        const TextStyle(color: Colors.amber, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Defeated: $defeats times',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value / 300).clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.6)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text(
              '$value',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _enemyIcon(AiBehavior behavior) {
    return switch (behavior) {
      AiBehavior.aggressive => Icons.whatshot,
      AiBehavior.defensive => Icons.shield,
      AiBehavior.random => Icons.pest_control,
      AiBehavior.boss => Icons.local_fire_department,
    };
  }
}
