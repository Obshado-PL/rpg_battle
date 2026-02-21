class SkillTreeNode {
  final String skillId;
  final int tier;
  final int choice; // 0 or 1
  final int levelRequired;

  const SkillTreeNode({
    required this.skillId,
    required this.tier,
    required this.choice,
    required this.levelRequired,
  });

  factory SkillTreeNode.fromJson(Map<String, dynamic> json) {
    return SkillTreeNode(
      skillId: json['skillId'] as String,
      tier: json['tier'] as int,
      choice: json['choice'] as int,
      levelRequired: json['levelRequired'] as int,
    );
  }
}

class SkillTree {
  final String heroClass;
  final List<SkillTreeNode> nodes;

  const SkillTree({
    required this.heroClass,
    required this.nodes,
  });

  factory SkillTree.fromJson(Map<String, dynamic> json) {
    return SkillTree(
      heroClass: json['heroClass'] as String,
      nodes: (json['nodes'] as List)
          .map((e) => SkillTreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<SkillTreeNode> nodesForTier(int tier) =>
      nodes.where((n) => n.tier == tier).toList();

  int get maxTier => nodes.fold(0, (max, n) => n.tier > max ? n.tier : max);
}
