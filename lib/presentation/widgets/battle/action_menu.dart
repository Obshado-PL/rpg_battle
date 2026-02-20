import 'package:flutter/material.dart';

import '../../../data/models/battle_action.dart';
import '../../../data/models/character.dart';
import '../../../data/models/item.dart';
import '../../../data/models/skill.dart';
import '../common/rpg_button.dart';

enum MenuState { main, skills, items, targetEnemy, targetAlly }

class ActionMenu extends StatefulWidget {
  final Character activeHero;
  final Map<String, Skill> skills;
  final Map<String, Item> items;
  final List<InventorySlot> inventory;
  final void Function(BattleAction action) onActionSelected;
  final void Function(MenuState state) onMenuStateChanged;

  const ActionMenu({
    super.key,
    required this.activeHero,
    required this.skills,
    required this.items,
    required this.inventory,
    required this.onActionSelected,
    required this.onMenuStateChanged,
  });

  @override
  ActionMenuState createState() => ActionMenuState();
}

class ActionMenuState extends State<ActionMenu> {
  MenuState _menuState = MenuState.main;
  String? _pendingSkillId;
  String? _pendingItemId;

  void _setMenuState(MenuState state) {
    setState(() => _menuState = state);
    widget.onMenuStateChanged(state);
  }

  @override
  void didUpdateWidget(ActionMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeHero.id != oldWidget.activeHero.id) {
      _setMenuState(MenuState.main);
      _pendingSkillId = null;
      _pendingItemId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _buildCurrentMenu(),
    );
  }

  Widget _buildCurrentMenu() {
    switch (_menuState) {
      case MenuState.main:
        return _buildMainMenu();
      case MenuState.skills:
        return _buildSkillMenu();
      case MenuState.items:
        return _buildItemMenu();
      case MenuState.targetEnemy:
      case MenuState.targetAlly:
        return _buildWaitingForTarget();
    }
  }

  Widget _buildMainMenu() {
    return Padding(
      key: const ValueKey('main_menu'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: RpgButton(
                  label: 'Attack',
                  icon: Icons.sports_martial_arts,
                  color: Colors.red[700],
                  onTap: () {
                    _setMenuState(MenuState.targetEnemy);
                    _pendingSkillId = null;
                    _pendingItemId = null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RpgButton(
                  label: 'Skill',
                  icon: Icons.auto_awesome,
                  color: Colors.purple[700],
                  onTap: () => _setMenuState(MenuState.skills),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RpgButton(
                  label: 'Defend',
                  icon: Icons.shield,
                  color: Colors.blue[700],
                  onTap: () {
                    widget.onActionSelected(BattleAction(
                      actorId: widget.activeHero.id,
                      isHero: true,
                      actionType: ActionType.defend,
                    ));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RpgButton(
                  label: 'Item',
                  icon: Icons.inventory_2,
                  color: Colors.green[700],
                  onTap: () => _setMenuState(MenuState.items),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RpgButton(
                  label: 'Flee',
                  icon: Icons.directions_run,
                  color: Colors.grey[700],
                  onTap: () {
                    widget.onActionSelected(BattleAction(
                      actorId: widget.activeHero.id,
                      isHero: true,
                      actionType: ActionType.flee,
                    ));
                  },
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillMenu() {
    final heroSkills = widget.activeHero.skillIds
        .map((id) => widget.skills[id])
        .whereType<Skill>()
        .toList();

    return Padding(
      key: const ValueKey('skill_menu'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...heroSkills.map((skill) {
            final hasEnoughMp = widget.activeHero.currentMp >= skill.mpCost;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RpgButton(
                label: '${skill.name} (${skill.mpCost} MP)',
                icon: skill.type == SkillType.healing
                    ? Icons.healing
                    : skill.type == SkillType.magical
                        ? Icons.local_fire_department
                        : Icons.flash_on,
                color: hasEnoughMp ? Colors.purple[700] : Colors.grey[700],
                enabled: hasEnoughMp,
                onTap: () {
                  _pendingSkillId = skill.id;
                  if (skill.isAoe) {
                    widget.onActionSelected(BattleAction(
                      actorId: widget.activeHero.id,
                      isHero: true,
                      actionType: ActionType.skill,
                      skillId: skill.id,
                      targetAll: true,
                    ));
                  } else if (skill.isHealing) {
                    _setMenuState(MenuState.targetAlly);
                  } else {
                    _setMenuState(MenuState.targetEnemy);
                  }
                },
              ),
            );
          }),
          RpgButton(
            label: 'Back',
            icon: Icons.arrow_back,
            color: Colors.grey[600],
            onTap: () => _setMenuState(MenuState.main),
          ),
        ],
      ),
    );
  }

  Widget _buildItemMenu() {
    final availableItems = widget.inventory
        .where((slot) => slot.quantity > 0)
        .map((slot) {
      final item = widget.items[slot.itemId];
      return item != null ? (item: item, quantity: slot.quantity) : null;
    })
        .whereType<({Item item, int quantity})>()
        .toList();

    return Padding(
      key: const ValueKey('item_menu'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (availableItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'No items!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ...availableItems.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RpgButton(
                label: '${entry.item.name} x${entry.quantity}',
                icon: Icons.inventory_2,
                color: Colors.green[700],
                onTap: () {
                  _pendingItemId = entry.item.id;
                  _setMenuState(MenuState.targetAlly);
                },
              ),
            );
          }),
          RpgButton(
            label: 'Back',
            icon: Icons.arrow_back,
            color: Colors.grey[600],
            onTap: () => _setMenuState(MenuState.main),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForTarget() {
    final targetType =
        _menuState == MenuState.targetEnemy ? 'an enemy' : 'an ally';
    return Padding(
      key: const ValueKey('target_select'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select $targetType',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.yellow,
                ),
          ),
          const SizedBox(height: 8),
          RpgButton(
            label: 'Cancel',
            icon: Icons.close,
            color: Colors.grey[600],
            onTap: () => _setMenuState(MenuState.main),
          ),
        ],
      ),
    );
  }

  /// Called by the battle screen when a target is selected.
  void onTargetSelected(String targetId) {
    if (_pendingSkillId != null) {
      widget.onActionSelected(BattleAction(
        actorId: widget.activeHero.id,
        isHero: true,
        actionType: ActionType.skill,
        skillId: _pendingSkillId,
        targetId: targetId,
      ));
    } else if (_pendingItemId != null) {
      widget.onActionSelected(BattleAction(
        actorId: widget.activeHero.id,
        isHero: true,
        actionType: ActionType.item,
        itemId: _pendingItemId,
        targetId: targetId,
      ));
    } else {
      // Basic attack
      widget.onActionSelected(BattleAction(
        actorId: widget.activeHero.id,
        isHero: true,
        actionType: ActionType.attack,
        targetId: targetId,
      ));
    }
    _setMenuState(MenuState.main);
    _pendingSkillId = null;
    _pendingItemId = null;
  }
}
