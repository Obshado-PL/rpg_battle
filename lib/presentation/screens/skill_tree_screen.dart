import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/character.dart';
import '../../data/models/skill.dart';
import '../../data/models/skill_tree.dart';
import '../../domain/skill_tree_system.dart';
import '../providers/game_providers.dart';

class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = ref.watch(partyProvider);

    return DefaultTabController(
      length: party.length,
      child: Scaffold(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.account_tree, color: Colors.purpleAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Skill Trees',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.purpleAccent),
                      ),
                    ],
                  ),
                ),

                // Tab bar for each hero
                TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.purpleAccent,
                  tabs: party.map((hero) {
                    final color = _classColor(hero.heroClass);
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_classIcon(hero.heroClass),
                              size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(
                            '${hero.name} Lv.${hero.level}',
                            style: TextStyle(color: color),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    children: party
                        .map((hero) => _HeroSkillTree(hero: hero))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _classColor(HeroClass heroClass) => switch (heroClass) {
        HeroClass.warrior => Colors.orange,
        HeroClass.mage => Colors.purple,
        HeroClass.healer => Colors.green,
        HeroClass.rogue => Colors.amber,
      };

  static IconData _classIcon(HeroClass heroClass) => switch (heroClass) {
        HeroClass.warrior => Icons.security,
        HeroClass.mage => Icons.auto_fix_high,
        HeroClass.healer => Icons.favorite,
        HeroClass.rogue => Icons.flash_on,
      };
}

class _HeroSkillTree extends ConsumerWidget {
  final Character hero;

  const _HeroSkillTree({required this.hero});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillTreeSystem = ref.watch(skillTreeSystemProvider);
    final choices = ref.watch(skillTreeChoicesProvider);
    final gameData = ref.watch(gameDataProvider);
    final tree = skillTreeSystem.getTree(hero.heroClass);

    if (tree == null) {
      return const Center(
        child: Text('No skill tree available',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Base skills
        _buildSectionHeader('Base Skills', Colors.white54),
        const SizedBox(height: 8),
        _buildBaseSkills(gameData.skills),
        const SizedBox(height: 24),

        // Skill tree tiers
        for (var tier = 1; tier <= tree.maxTier; tier++) ...[
          _buildTierSection(
            context,
            ref,
            tier: tier,
            tree: tree,
            choices: choices,
            skills: gameData.skills,
            skillTreeSystem: skillTreeSystem,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBaseSkills(Map<String, Skill> skills) {
    // Default party starts with 2 skills
    final baseIds = switch (hero.heroClass) {
      HeroClass.warrior => ['warrior_slash', 'warrior_power_strike'],
      HeroClass.mage => ['mage_fireball', 'mage_ice_storm'],
      HeroClass.healer => ['healer_heal', 'healer_revive'],
      HeroClass.rogue => ['rogue_backstab', 'rogue_poison_dart'],
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: baseIds.map((id) {
        final skill = skills[id];
        if (skill == null) return const SizedBox.shrink();
        return Chip(
          avatar: Icon(_skillTypeIcon(skill), size: 14, color: Colors.white70),
          label: Text(skill.name, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          side: const BorderSide(color: Colors.white24),
        );
      }).toList(),
    );
  }

  Widget _buildTierSection(
    BuildContext context,
    WidgetRef ref, {
    required int tier,
    required SkillTree tree,
    required Map<String, String> choices,
    required Map<String, Skill> skills,
    required SkillTreeSystem skillTreeSystem,
  }) {
    final tierNodes = tree.nodesForTier(tier);
    final key = '${hero.heroClass.name}_tier$tier';
    final chosenSkillId = choices[key];
    final canChoose = skillTreeSystem.canChoose(
      hero: hero,
      tier: tier,
      choices: choices,
    );
    final isLocked = hero.level < tierNodes.first.levelRequired && chosenSkillId == null;
    final levelReq = tierNodes.first.levelRequired;

    final headerColor = isLocked
        ? Colors.grey
        : chosenSkillId != null
            ? Colors.greenAccent
            : Colors.purpleAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Tier $tier (Lv.$levelReq)',
          headerColor,
        ),
        if (isLocked)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              'Unlocks at level $levelReq',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < tierNodes.length; i++) ...[
              if (i > 0) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('OR',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
              Expanded(
                child: _buildNodeCard(
                  context,
                  ref,
                  node: tierNodes[i],
                  skill: skills[tierNodes[i].skillId],
                  isChosen: chosenSkillId == tierNodes[i].skillId,
                  isOtherChosen: chosenSkillId != null &&
                      chosenSkillId != tierNodes[i].skillId,
                  canChoose: canChoose,
                  isLocked: isLocked,
                  tier: tier,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNodeCard(
    BuildContext context,
    WidgetRef ref, {
    required SkillTreeNode node,
    required Skill? skill,
    required bool isChosen,
    required bool isOtherChosen,
    required bool canChoose,
    required bool isLocked,
    required int tier,
  }) {
    if (skill == null) return const SizedBox.shrink();

    final borderColor = isChosen
        ? Colors.greenAccent
        : canChoose
            ? Colors.purpleAccent
            : isLocked
                ? Colors.grey[800]!
                : Colors.white24;

    final bgColor = isChosen
        ? Colors.greenAccent.withValues(alpha: 0.1)
        : isOtherChosen
            ? Colors.grey[900]!.withValues(alpha: 0.5)
            : isLocked
                ? Colors.grey[900]!
                : Colors.purpleAccent.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: canChoose
          ? () => _confirmChoice(context, ref, skill, node, tier)
          : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isChosen ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _skillTypeIcon(skill),
                  size: 14,
                  color: isLocked ? Colors.grey : Colors.white70,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    skill.name,
                    style: TextStyle(
                      color: isLocked ? Colors.grey : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isChosen)
                  const Icon(Icons.check_circle,
                      size: 14, color: Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              skill.description,
              style: TextStyle(
                color: isLocked ? Colors.grey[700] : Colors.white54,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'MP: ${skill.mpCost}',
                  style: TextStyle(
                    color: isLocked ? Colors.grey[700] : Colors.blue[300],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pow: ${skill.power}',
                  style: TextStyle(
                    color: isLocked ? Colors.grey[700] : Colors.orange[300],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmChoice(
    BuildContext context,
    WidgetRef ref,
    Skill skill,
    SkillTreeNode node,
    int tier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Learn ${skill.name}?',
          style: const TextStyle(color: Colors.purpleAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skill.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'MP Cost: ${skill.mpCost}  |  Power: ${skill.power}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'This choice is permanent for this tier.',
              style: TextStyle(color: Colors.amber, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applyChoice(ref, skill.id, tier);
            },
            child: const Text('Learn',
                style: TextStyle(color: Colors.purpleAccent)),
          ),
        ],
      ),
    );
  }

  void _applyChoice(WidgetRef ref, String skillId, int tier) {
    final key = '${hero.heroClass.name}_tier$tier';

    // Update skill tree choices
    ref.read(skillTreeChoicesProvider.notifier).choose(key, skillId);

    // Update hero's skill list
    final skillTreeSystem = ref.read(skillTreeSystemProvider);
    final choices = ref.read(skillTreeChoicesProvider);
    final updatedHero = skillTreeSystem.applyChoice(
      hero: hero,
      skillId: skillId,
      tier: tier,
      choices: choices,
    );
    ref.read(partyProvider.notifier).updateHeroSkills(
          hero.id,
          updatedHero.skillIds,
        );

    // Auto-save
    collectAndSave(ref);
  }

  static IconData _skillTypeIcon(Skill skill) {
    if (skill.type == SkillType.healing) return Icons.favorite;
    if (skill.type == SkillType.magical) return Icons.auto_fix_high;
    return Icons.sports_martial_arts;
  }
}
