import '../data/models/battle_action.dart';
import '../data/models/battle_state.dart';
import '../data/models/character.dart';
import '../data/models/enemy.dart';
import '../data/models/equipment.dart';
import '../data/models/item.dart';
import '../data/models/skill.dart';
import '../data/models/stats.dart';
import 'damage_calculator.dart';
import 'enemy_ai.dart';
import 'equipment_system.dart';
import 'turn_manager.dart';

class BattleAnimationEvent {
  final String type; // 'attack', 'skill', 'heal', 'damage', 'death', 'miss', 'defend'
  final String actorId;
  final String? targetId;
  final int? value;
  final bool isCritical;
  final String? effectKey;
  final String? message;

  const BattleAnimationEvent({
    required this.type,
    required this.actorId,
    this.targetId,
    this.value,
    this.isCritical = false,
    this.effectKey,
    this.message,
  });
}

class BattleActionResult {
  final BattleState state;
  final List<String> messages;
  final List<BattleAnimationEvent> animations;

  const BattleActionResult({
    required this.state,
    required this.messages,
    required this.animations,
  });
}

class BattleEngine {
  final TurnManager _turnManager;
  final DamageCalculator _damageCalculator;
  final EnemyAi _enemyAi;
  final Map<String, Skill> _skills;
  final Map<String, Item> _items;
  final Map<String, Equipment> _equipment;

  BattleEngine({
    required TurnManager turnManager,
    required DamageCalculator damageCalculator,
    required EnemyAi enemyAi,
    required Map<String, Skill> skills,
    required Map<String, Item> items,
    required Map<String, Equipment> equipment,
  })  : _turnManager = turnManager,
        _damageCalculator = damageCalculator,
        _enemyAi = enemyAi,
        _skills = skills,
        _items = items,
        _equipment = equipment;

  Stats _effectiveStats(Character hero) {
    return EquipmentSystem.computeEffectiveStats(hero, _equipment);
  }

  BattleState initBattle({
    required List<Character> party,
    required List<Enemy> enemies,
    required List<InventorySlot> inventory,
  }) {
    return BattleState(
      party: party,
      enemies: enemies,
      phase: BattlePhase.starting,
      turnOrder: [],
      currentTurnIndex: 0,
      battleLog: ['A group of enemies appeared!'],
      inventory: inventory,
      roundNumber: 1,
    );
  }

  BattleState startRound(BattleState state) {
    final turnOrder = _turnManager.calculateTurnOrder(
      party: state.party,
      enemies: state.enemies,
    );

    if (turnOrder.isEmpty) return state;

    final firstActorId = turnOrder.first;
    final isHero = state.party.any((h) => h.id == firstActorId);

    return state.copyWith(
      turnOrder: turnOrder,
      currentTurnIndex: 0,
      phase: isHero ? BattlePhase.playerInput : BattlePhase.enemyTurn,
      activeHeroId: isHero ? firstActorId : null,
    );
  }

  BattleState advanceTurn(BattleState state) {
    final nextIndex = state.currentTurnIndex + 1;

    if (nextIndex >= state.turnOrder.length) {
      // Round complete — reset defend flags and start new round
      final resetParty =
          state.party.map((h) => h.copyWith(isDefending: false)).toList();
      final resetEnemies = state.enemies; // enemies defend flag handled inline
      return startRound(state.copyWith(
        party: resetParty,
        enemies: resetEnemies,
        roundNumber: state.roundNumber + 1,
      ));
    }

    final nextActorId = state.turnOrder[nextIndex];

    // Skip dead actors
    final isAlive = _isActorAlive(state, nextActorId);
    if (!isAlive) {
      return advanceTurn(state.copyWith(currentTurnIndex: nextIndex));
    }

    final isHero = state.party.any((h) => h.id == nextActorId);

    return state.copyWith(
      currentTurnIndex: nextIndex,
      phase: isHero ? BattlePhase.playerInput : BattlePhase.enemyTurn,
      activeHeroId: isHero ? nextActorId : null,
    );
  }

  BattleActionResult executeAction(BattleState state, BattleAction action) {
    var newState = state;
    final messages = <String>[];
    final animations = <BattleAnimationEvent>[];

    switch (action.actionType) {
      case ActionType.attack:
        final result = _executeAttack(newState, action);
        newState = result.state;
        messages.addAll(result.messages);
        animations.addAll(result.animations);
        break;

      case ActionType.skill:
        final result = _executeSkill(newState, action);
        newState = result.state;
        messages.addAll(result.messages);
        animations.addAll(result.animations);
        break;

      case ActionType.defend:
        final result = _executeDefend(newState, action);
        newState = result.state;
        messages.addAll(result.messages);
        animations.addAll(result.animations);
        break;

      case ActionType.item:
        final result = _executeItem(newState, action);
        newState = result.state;
        messages.addAll(result.messages);
        animations.addAll(result.animations);
        break;

      case ActionType.flee:
        final result = _executeFlee(newState);
        newState = result.state;
        messages.addAll(result.messages);
        animations.addAll(result.animations);
        break;
    }

    // Check victory/defeat
    if (newState.enemies.every((e) => !e.isAlive)) {
      final totalXp =
          newState.enemies.fold<int>(0, (sum, e) => sum + e.xpReward);
      final totalGold =
          newState.enemies.fold<int>(0, (sum, e) => sum + e.goldReward);
      newState = newState.copyWith(
        phase: BattlePhase.victory,
        result: BattleResult(totalXp: totalXp, totalGold: totalGold),
      );
      messages.add('Victory!');
    } else if (newState.party.every((h) => !h.isAlive)) {
      newState = newState.copyWith(phase: BattlePhase.defeat);
      messages.add('Defeat...');
    }

    newState = newState.copyWith(
      battleLog: [...newState.battleLog, ...messages],
    );

    return BattleActionResult(
      state: newState,
      messages: messages,
      animations: animations,
    );
  }

  BattleAction getEnemyAction(BattleState state) {
    final currentActorId = state.turnOrder[state.currentTurnIndex];
    final enemy = state.enemies.firstWhere((e) => e.id == currentActorId);
    return _enemyAi.selectAction(
      enemy: enemy,
      party: state.party,
      allEnemies: state.enemies,
    );
  }

  // --- Private execution methods ---

  BattleActionResult _executeAttack(BattleState state, BattleAction action) {
    final messages = <String>[];
    final animations = <BattleAnimationEvent>[];
    var newState = state;

    final actorName = _getActorName(state, action.actorId);

    if (action.isHero) {
      // Hero attacks enemy
      final hero = state.party.firstWhere((h) => h.id == action.actorId);
      final targetId = action.targetId!;
      final enemy = state.enemies.firstWhere((e) => e.id == targetId);

      final dmg = _damageCalculator.calculateBasicAttack(
        attackStat: _effectiveStats(hero).attack,
        defenseStat: enemy.stats.defense,
        isDefending: false,
      );

      if (dmg.isMiss) {
        messages.add('$actorName attacks ${enemy.name}... Miss!');
        animations.add(BattleAnimationEvent(
          type: 'miss',
          actorId: action.actorId,
          targetId: targetId,
          message: 'MISS',
        ));
      } else {
        final newHp = (enemy.currentHp - dmg.damage).clamp(0, enemy.stats.maxHp);
        final updatedEnemies = state.enemies.map((e) {
          if (e.id == targetId) return e.copyWith(currentHp: newHp);
          return e;
        }).toList();
        newState = newState.copyWith(enemies: updatedEnemies);

        final critText = dmg.isCritical ? ' Critical hit!' : '';
        messages.add(
            '$actorName attacks ${enemy.name} for ${dmg.damage} damage!$critText');

        animations.add(BattleAnimationEvent(
          type: 'attack',
          actorId: action.actorId,
          targetId: targetId,
          value: dmg.damage,
          isCritical: dmg.isCritical,
        ));

        if (newHp <= 0) {
          messages.add('${enemy.name} was defeated!');
          animations.add(BattleAnimationEvent(
            type: 'death',
            actorId: targetId,
          ));
        }
      }
    } else {
      // Enemy attacks hero
      final enemy = state.enemies.firstWhere((e) => e.id == action.actorId);
      final targetId = action.targetId!;
      final hero = state.party.firstWhere((h) => h.id == targetId);

      final dmg = _damageCalculator.calculateBasicAttack(
        attackStat: enemy.stats.attack,
        defenseStat: _effectiveStats(hero).defense,
        isDefending: hero.isDefending,
      );

      if (dmg.isMiss) {
        messages.add('${enemy.name} attacks ${hero.name}... Miss!');
        animations.add(BattleAnimationEvent(
          type: 'miss',
          actorId: action.actorId,
          targetId: targetId,
          message: 'MISS',
        ));
      } else {
        final newHp =
            (hero.currentHp - dmg.damage).clamp(0, _effectiveStats(hero).maxHp);
        final updatedParty = state.party.map((h) {
          if (h.id == targetId) return h.copyWith(currentHp: newHp);
          return h;
        }).toList();
        newState = newState.copyWith(party: updatedParty);

        final critText = dmg.isCritical ? ' Critical hit!' : '';
        messages.add(
            '${enemy.name} attacks ${hero.name} for ${dmg.damage} damage!$critText');

        animations.add(BattleAnimationEvent(
          type: 'damage',
          actorId: action.actorId,
          targetId: targetId,
          value: dmg.damage,
          isCritical: dmg.isCritical,
        ));

        if (newHp <= 0) {
          messages.add('${hero.name} was knocked out!');
          animations.add(BattleAnimationEvent(
            type: 'death',
            actorId: targetId,
          ));
        }
      }
    }

    return BattleActionResult(
      state: newState,
      messages: messages,
      animations: animations,
    );
  }

  BattleActionResult _executeSkill(BattleState state, BattleAction action) {
    final messages = <String>[];
    final animations = <BattleAnimationEvent>[];
    var newState = state;

    final skill = _skills[action.skillId];
    if (skill == null) {
      messages.add('Unknown skill!');
      return BattleActionResult(
          state: newState, messages: messages, animations: animations);
    }

    final actorName = _getActorName(state, action.actorId);

    // Deduct MP for hero skills
    if (action.isHero) {
      final hero = state.party.firstWhere((h) => h.id == action.actorId);
      if (hero.currentMp < skill.mpCost) {
        messages.add('$actorName doesn\'t have enough MP!');
        return BattleActionResult(
            state: newState, messages: messages, animations: animations);
      }
      final updatedParty = state.party.map((h) {
        if (h.id == action.actorId) {
          return h.copyWith(currentMp: h.currentMp - skill.mpCost);
        }
        return h;
      }).toList();
      newState = newState.copyWith(party: updatedParty);
    }

    if (skill.isHealing) {
      newState = _applyHealing(newState, action, skill, messages, animations);
    } else if (skill.isAoe) {
      newState =
          _applyAoeSkill(newState, action, skill, messages, animations);
    } else {
      newState = _applySingleTargetSkill(
          newState, action, skill, messages, animations);
    }

    return BattleActionResult(
      state: newState,
      messages: messages,
      animations: animations,
    );
  }

  BattleState _applyHealing(
    BattleState state,
    BattleAction action,
    Skill skill,
    List<String> messages,
    List<BattleAnimationEvent> animations,
  ) {
    final actorName = _getActorName(state, action.actorId);
    final targetId = action.targetId ?? action.actorId;

    int magicAttack;
    if (action.isHero) {
      final caster = state.party.firstWhere((h) => h.id == action.actorId);
      magicAttack = _effectiveStats(caster).magicAttack;
    } else {
      magicAttack = state.enemies
          .firstWhere((e) => e.id == action.actorId)
          .stats
          .magicAttack;
    }

    final healAmount = _damageCalculator.calculateHealing(
      magicAttackStat: magicAttack,
      skillPower: skill.power,
    );

    // Group heal: heal all living allies
    if (skill.targetType == TargetType.allAllies) {
      messages.add('$actorName casts ${skill.name}!');
      var updatedParty = List<Character>.from(state.party);
      for (var i = 0; i < updatedParty.length; i++) {
        final ally = updatedParty[i];
        if (!ally.isAlive) continue;
        final allyMaxHp = _effectiveStats(ally).maxHp;
        final newHp = (ally.currentHp + healAmount).clamp(0, allyMaxHp);
        final actualHeal = newHp - ally.currentHp;
        updatedParty[i] = ally.copyWith(currentHp: newHp);
        if (actualHeal > 0) {
          messages.add('${ally.name} restored $actualHeal HP!');
          animations.add(BattleAnimationEvent(
            type: 'heal',
            actorId: action.actorId,
            targetId: ally.id,
            value: actualHeal,
            effectKey: skill.animationKey,
          ));
        }
      }
      return state.copyWith(party: updatedParty);
    }

    // Healing targets allies
    final target = state.party.firstWhere((h) => h.id == targetId);

    // Handle revive
    if (skill.id == 'healer_revive' && !target.isAlive) {
      final tStats = _effectiveStats(target);
      final reviveHp = (tStats.maxHp * 0.25).round().clamp(1, tStats.maxHp);
      final updatedParty = state.party.map((h) {
        if (h.id == targetId) return h.copyWith(currentHp: reviveHp);
        return h;
      }).toList();

      messages.add('$actorName casts ${skill.name} on ${target.name}! Revived with $reviveHp HP!');
      animations.add(BattleAnimationEvent(
        type: 'heal',
        actorId: action.actorId,
        targetId: targetId,
        value: reviveHp,
        effectKey: skill.animationKey,
      ));

      return state.copyWith(party: updatedParty);
    }

    // Normal healing (can't heal dead allies)
    if (!target.isAlive) {
      messages.add('${target.name} is knocked out! Can\'t heal!');
      return state;
    }

    final newHp =
        (target.currentHp + healAmount).clamp(0, _effectiveStats(target).maxHp);
    final actualHeal = newHp - target.currentHp;

    final updatedParty = state.party.map((h) {
      if (h.id == targetId) return h.copyWith(currentHp: newHp);
      return h;
    }).toList();

    messages.add(
        '$actorName casts ${skill.name} on ${target.name}! Restored $actualHeal HP!');
    animations.add(BattleAnimationEvent(
      type: 'heal',
      actorId: action.actorId,
      targetId: targetId,
      value: actualHeal,
      effectKey: skill.animationKey,
    ));

    return state.copyWith(party: updatedParty);
  }

  BattleState _applyAoeSkill(
    BattleState state,
    BattleAction action,
    Skill skill,
    List<String> messages,
    List<BattleAnimationEvent> animations,
  ) {
    final actorName = _getActorName(state, action.actorId);
    messages.add('$actorName casts ${skill.name}!');

    animations.add(BattleAnimationEvent(
      type: 'skill',
      actorId: action.actorId,
      effectKey: skill.animationKey,
    ));

    if (action.isHero) {
      // Hero AoE hits all enemies
      final hero = state.party.firstWhere((h) => h.id == action.actorId);
      final heroStats = _effectiveStats(hero);
      var updatedEnemies = List<Enemy>.from(state.enemies);

      for (var i = 0; i < updatedEnemies.length; i++) {
        final enemy = updatedEnemies[i];
        if (!enemy.isAlive) continue;

        DamageResult dmg;
        if (skill.type == SkillType.magical) {
          dmg = _damageCalculator.calculateMagicalDamage(
            magicAttackStat: heroStats.magicAttack,
            magicDefenseStat: enemy.stats.magicDefense,
            skillPower: skill.power,
          );
        } else {
          dmg = _damageCalculator.calculatePhysicalDamage(
            attackStat: heroStats.attack,
            defenseStat: enemy.stats.defense,
            skillPower: skill.power,
            accuracy: skill.accuracy,
          );
        }

        if (!dmg.isMiss) {
          final newHp =
              (enemy.currentHp - dmg.damage).clamp(0, enemy.stats.maxHp);
          updatedEnemies[i] = enemy.copyWith(currentHp: newHp);
          messages.add('${enemy.name} takes ${dmg.damage} damage!');

          animations.add(BattleAnimationEvent(
            type: 'damage',
            actorId: action.actorId,
            targetId: enemy.id,
            value: dmg.damage,
          ));

          if (newHp <= 0) {
            messages.add('${enemy.name} was defeated!');
            animations
                .add(BattleAnimationEvent(type: 'death', actorId: enemy.id));
          }
        }
      }

      return state.copyWith(enemies: updatedEnemies);
    } else {
      // Enemy AoE hits all heroes
      final enemy = state.enemies.firstWhere((e) => e.id == action.actorId);
      var updatedParty = List<Character>.from(state.party);

      for (var i = 0; i < updatedParty.length; i++) {
        final hero = updatedParty[i];
        if (!hero.isAlive) continue;

        final heroStats = _effectiveStats(hero);
        DamageResult dmg;
        if (skill.type == SkillType.magical) {
          dmg = _damageCalculator.calculateMagicalDamage(
            magicAttackStat: enemy.stats.magicAttack,
            magicDefenseStat: heroStats.magicDefense,
            skillPower: skill.power,
            isDefending: hero.isDefending,
          );
        } else {
          dmg = _damageCalculator.calculatePhysicalDamage(
            attackStat: enemy.stats.attack,
            defenseStat: heroStats.defense,
            skillPower: skill.power,
            accuracy: skill.accuracy,
            isDefending: hero.isDefending,
          );
        }

        if (!dmg.isMiss) {
          final newHp =
              (hero.currentHp - dmg.damage).clamp(0, heroStats.maxHp);
          updatedParty[i] = hero.copyWith(currentHp: newHp);
          messages.add('${hero.name} takes ${dmg.damage} damage!');

          animations.add(BattleAnimationEvent(
            type: 'damage',
            actorId: action.actorId,
            targetId: hero.id,
            value: dmg.damage,
          ));

          if (newHp <= 0) {
            messages.add('${hero.name} was knocked out!');
            animations
                .add(BattleAnimationEvent(type: 'death', actorId: hero.id));
          }
        }
      }

      return state.copyWith(party: updatedParty);
    }
  }

  BattleState _applySingleTargetSkill(
    BattleState state,
    BattleAction action,
    Skill skill,
    List<String> messages,
    List<BattleAnimationEvent> animations,
  ) {
    final actorName = _getActorName(state, action.actorId);
    final targetId = action.targetId!;

    if (action.isHero) {
      final hero = state.party.firstWhere((h) => h.id == action.actorId);
      final heroStats = _effectiveStats(hero);
      final enemy = state.enemies.firstWhere((e) => e.id == targetId);

      DamageResult dmg;
      if (skill.type == SkillType.magical) {
        dmg = _damageCalculator.calculateMagicalDamage(
          magicAttackStat: heroStats.magicAttack,
          magicDefenseStat: enemy.stats.magicDefense,
          skillPower: skill.power,
        );
      } else {
        dmg = _damageCalculator.calculatePhysicalDamage(
          attackStat: heroStats.attack,
          defenseStat: enemy.stats.defense,
          skillPower: skill.power,
          accuracy: skill.accuracy,
        );
      }

      if (dmg.isMiss) {
        messages.add('$actorName uses ${skill.name} on ${enemy.name}... Miss!');
        animations.add(BattleAnimationEvent(
          type: 'miss',
          actorId: action.actorId,
          targetId: targetId,
        ));
      } else {
        final newHp =
            (enemy.currentHp - dmg.damage).clamp(0, enemy.stats.maxHp);
        final updatedEnemies = state.enemies.map((e) {
          if (e.id == targetId) return e.copyWith(currentHp: newHp);
          return e;
        }).toList();

        final critText = dmg.isCritical ? ' Critical hit!' : '';
        messages.add(
            '$actorName uses ${skill.name} on ${enemy.name} for ${dmg.damage} damage!$critText');

        animations.add(BattleAnimationEvent(
          type: 'skill',
          actorId: action.actorId,
          targetId: targetId,
          value: dmg.damage,
          isCritical: dmg.isCritical,
          effectKey: skill.animationKey,
        ));

        if (newHp <= 0) {
          messages.add('${enemy.name} was defeated!');
          animations.add(
              BattleAnimationEvent(type: 'death', actorId: targetId));
        }

        return state.copyWith(enemies: updatedEnemies);
      }
    } else {
      final enemy = state.enemies.firstWhere((e) => e.id == action.actorId);
      final hero = state.party.firstWhere((h) => h.id == targetId);
      final heroStats = _effectiveStats(hero);

      DamageResult dmg;
      if (skill.type == SkillType.magical) {
        dmg = _damageCalculator.calculateMagicalDamage(
          magicAttackStat: enemy.stats.magicAttack,
          magicDefenseStat: heroStats.magicDefense,
          skillPower: skill.power,
          isDefending: hero.isDefending,
        );
      } else {
        dmg = _damageCalculator.calculatePhysicalDamage(
          attackStat: enemy.stats.attack,
          defenseStat: heroStats.defense,
          skillPower: skill.power,
          accuracy: skill.accuracy,
          isDefending: hero.isDefending,
        );
      }

      if (dmg.isMiss) {
        messages.add('${enemy.name} uses ${skill.name} on ${hero.name}... Miss!');
        animations.add(BattleAnimationEvent(
          type: 'miss',
          actorId: action.actorId,
          targetId: targetId,
        ));
      } else {
        final newHp =
            (hero.currentHp - dmg.damage).clamp(0, heroStats.maxHp);
        final updatedParty = state.party.map((h) {
          if (h.id == targetId) return h.copyWith(currentHp: newHp);
          return h;
        }).toList();

        messages.add(
            '${enemy.name} uses ${skill.name} on ${hero.name} for ${dmg.damage} damage!');

        animations.add(BattleAnimationEvent(
          type: 'skill',
          actorId: action.actorId,
          targetId: targetId,
          value: dmg.damage,
          effectKey: skill.animationKey,
        ));

        if (newHp <= 0) {
          messages.add('${hero.name} was knocked out!');
          animations.add(
              BattleAnimationEvent(type: 'death', actorId: targetId));
        }

        return state.copyWith(party: updatedParty);
      }
    }

    return state;
  }

  BattleActionResult _executeDefend(BattleState state, BattleAction action) {
    final actorName = _getActorName(state, action.actorId);
    var newState = state;

    if (action.isHero) {
      final updatedParty = state.party.map((h) {
        if (h.id == action.actorId) return h.copyWith(isDefending: true);
        return h;
      }).toList();
      newState = newState.copyWith(party: updatedParty);
    }

    return BattleActionResult(
      state: newState,
      messages: ['$actorName is defending!'],
      animations: [
        BattleAnimationEvent(
          type: 'defend',
          actorId: action.actorId,
        ),
      ],
    );
  }

  BattleActionResult _executeItem(BattleState state, BattleAction action) {
    final messages = <String>[];
    final animations = <BattleAnimationEvent>[];

    final item = _items[action.itemId];
    if (item == null) {
      messages.add('Unknown item!');
      return BattleActionResult(
          state: state, messages: messages, animations: animations);
    }

    // Remove item from inventory
    var newInventory = state.inventory.map((slot) {
      if (slot.itemId == action.itemId) {
        return slot.copyWith(quantity: slot.quantity - 1);
      }
      return slot;
    }).where((slot) => slot.quantity > 0).toList();

    final actorName = _getActorName(state, action.actorId);
    final targetId = action.targetId ?? action.actorId;
    final target = state.party.firstWhere((h) => h.id == targetId);

    var updatedParty = List<Character>.from(state.party);
    final targetStats = _effectiveStats(target);

    switch (item.effect) {
      case ItemEffect.restoreHp:
        if (!target.isAlive) {
          messages.add('${target.name} is knocked out!');
          return BattleActionResult(
              state: state, messages: messages, animations: animations);
        }
        final newHp = (target.currentHp + item.power)
            .clamp(0, targetStats.maxHp);
        final actualHeal = newHp - target.currentHp;
        updatedParty = state.party.map((h) {
          if (h.id == targetId) return h.copyWith(currentHp: newHp);
          return h;
        }).toList();
        messages.add(
            '$actorName uses ${item.name} on ${target.name}! Restored $actualHeal HP!');
        animations.add(BattleAnimationEvent(
          type: 'heal',
          actorId: action.actorId,
          targetId: targetId,
          value: actualHeal,
          effectKey: 'heal',
        ));
        break;

      case ItemEffect.restoreMp:
        if (!target.isAlive) {
          messages.add('${target.name} is knocked out!');
          return BattleActionResult(
              state: state, messages: messages, animations: animations);
        }
        final newMp = (target.currentMp + item.power)
            .clamp(0, targetStats.maxMp);
        final actualRestore = newMp - target.currentMp;
        updatedParty = state.party.map((h) {
          if (h.id == targetId) return h.copyWith(currentMp: newMp);
          return h;
        }).toList();
        messages.add(
            '$actorName uses ${item.name} on ${target.name}! Restored $actualRestore MP!');
        animations.add(BattleAnimationEvent(
          type: 'heal',
          actorId: action.actorId,
          targetId: targetId,
          value: actualRestore,
          effectKey: 'heal',
        ));
        break;

      case ItemEffect.revive:
        if (target.isAlive) {
          messages.add('${target.name} is already alive!');
          return BattleActionResult(
              state: state, messages: messages, animations: animations);
        }
        final reviveHp =
            (targetStats.maxHp * item.power / 100).round().clamp(1, targetStats.maxHp);
        updatedParty = state.party.map((h) {
          if (h.id == targetId) return h.copyWith(currentHp: reviveHp);
          return h;
        }).toList();
        messages.add(
            '$actorName uses ${item.name} on ${target.name}! Revived with $reviveHp HP!');
        animations.add(BattleAnimationEvent(
          type: 'heal',
          actorId: action.actorId,
          targetId: targetId,
          value: reviveHp,
          effectKey: 'revive',
        ));
        break;
    }

    return BattleActionResult(
      state: state.copyWith(party: updatedParty, inventory: newInventory),
      messages: messages,
      animations: animations,
    );
  }

  BattleActionResult _executeFlee(BattleState state) {
    final hasBoss = state.enemies.any((e) => e.behavior == AiBehavior.boss);
    final partyAvgSpeed = state.party
            .where((h) => h.isAlive)
            .fold<int>(0, (sum, h) => sum + _effectiveStats(h).speed) ~/
        state.party.where((h) => h.isAlive).length.clamp(1, 99);
    final enemyAvgSpeed = state.enemies
            .where((e) => e.isAlive)
            .fold<int>(0, (sum, e) => sum + e.stats.speed) ~/
        state.enemies.where((e) => e.isAlive).length.clamp(1, 99);

    final fled = _damageCalculator.calculateFleeChance(
      partyAverageSpeed: partyAvgSpeed,
      enemyAverageSpeed: enemyAvgSpeed,
      isBoss: hasBoss,
    );

    if (fled) {
      return BattleActionResult(
        state: state.copyWith(phase: BattlePhase.fled),
        messages: ['Got away safely!'],
        animations: [],
      );
    } else {
      return BattleActionResult(
        state: state,
        messages: ['Could not escape!'],
        animations: [],
      );
    }
  }

  // --- Helpers ---

  String _getActorName(BattleState state, String actorId) {
    final hero = state.party.where((h) => h.id == actorId).firstOrNull;
    if (hero != null) return hero.name;
    final enemy = state.enemies.where((e) => e.id == actorId).firstOrNull;
    if (enemy != null) return enemy.name;
    return 'Unknown';
  }

  bool _isActorAlive(BattleState state, String actorId) {
    final hero = state.party.where((h) => h.id == actorId).firstOrNull;
    if (hero != null) return hero.isAlive;
    final enemy = state.enemies.where((e) => e.id == actorId).firstOrNull;
    if (enemy != null) return enemy.isAlive;
    return false;
  }
}
