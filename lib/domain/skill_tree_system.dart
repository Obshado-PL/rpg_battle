import '../data/models/character.dart';
import '../data/models/skill_tree.dart';

class SkillTreeSystem {
  final Map<String, SkillTree> _trees;

  SkillTreeSystem(List<SkillTree> trees)
      : _trees = {for (final t in trees) t.heroClass: t};

  SkillTree? getTree(HeroClass heroClass) => _trees[heroClass.name];

  /// Check if a hero can choose a skill at the given tier.
  bool canChoose({
    required Character hero,
    required int tier,
    required Map<String, String> choices,
  }) {
    final tree = getTree(hero.heroClass);
    if (tree == null) return false;

    final tierNodes = tree.nodesForTier(tier);
    if (tierNodes.isEmpty) return false;

    // Already chosen this tier?
    final key = '${hero.heroClass.name}_tier$tier';
    if (choices.containsKey(key)) return false;

    // Must meet level requirement
    if (hero.level < tierNodes.first.levelRequired) return false;

    // Must have chosen all previous tiers
    for (var t = 1; t < tier; t++) {
      final prevKey = '${hero.heroClass.name}_tier$t';
      if (!choices.containsKey(prevKey)) return false;
    }

    return true;
  }

  /// Get the available skill choices for a tier (returns 2 nodes).
  List<SkillTreeNode> getChoicesForTier(HeroClass heroClass, int tier) {
    final tree = getTree(heroClass);
    if (tree == null) return [];
    return tree.nodesForTier(tier);
  }

  /// Apply a skill tree choice: returns updated hero with the new skill.
  Character applyChoice({
    required Character hero,
    required String skillId,
    required int tier,
    required Map<String, String> choices,
  }) {
    final tree = getTree(hero.heroClass);
    if (tree == null) return hero;

    // Remove any previously chosen skill for this tier (in case of reset)
    final key = '${hero.heroClass.name}_tier$tier';
    final oldSkillId = choices[key];
    var newSkills = List<String>.from(hero.skillIds);
    if (oldSkillId != null) {
      newSkills.remove(oldSkillId);
    }

    // Add the new skill
    if (!newSkills.contains(skillId)) {
      newSkills.add(skillId);
    }

    return hero.copyWith(skillIds: newSkills);
  }

  /// Reset all skill tree choices for a hero class.
  /// Returns the hero with tree skills removed.
  Character resetTree({
    required Character hero,
    required Map<String, String> choices,
  }) {
    final tree = getTree(hero.heroClass);
    if (tree == null) return hero;

    // Collect all skill IDs from the tree
    final treeSkillIds = tree.nodes.map((n) => n.skillId).toSet();

    // Remove tree skills from hero
    final newSkills =
        hero.skillIds.where((id) => !treeSkillIds.contains(id)).toList();

    return hero.copyWith(skillIds: newSkills);
  }

  /// Get all skills that should be on a hero based on current choices.
  List<String> getChosenSkillIds(HeroClass heroClass, Map<String, String> choices) {
    final result = <String>[];
    final tree = getTree(heroClass);
    if (tree == null) return result;

    for (var tier = 1; tier <= tree.maxTier; tier++) {
      final key = '${heroClass.name}_tier$tier';
      final chosenId = choices[key];
      if (chosenId != null) result.add(chosenId);
    }
    return result;
  }
}
