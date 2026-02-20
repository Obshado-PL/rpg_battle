enum ActionType { attack, skill, defend, item, flee }

class BattleAction {
  final String actorId;
  final bool isHero;
  final ActionType actionType;
  final String? skillId;
  final String? itemId;
  final String? targetId;
  final bool targetAll;

  const BattleAction({
    required this.actorId,
    required this.isHero,
    required this.actionType,
    this.skillId,
    this.itemId,
    this.targetId,
    this.targetAll = false,
  });
}
