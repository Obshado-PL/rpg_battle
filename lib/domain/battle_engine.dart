import '../data/models/battle_action.dart';
import '../data/models/battle_state.dart';
import '../data/models/character.dart';
import '../data/models/enemy.dart';
import '../data/models/equipment.dart';
import '../data/models/item.dart';
import '../data/models/skill.dart';
import '../data/models/stats.dart';
import '../data/models/status_effect.dart';
import 'damage_calculator.dart';
import 'enemy_ai.dart';
import 'equipment_system.dart';
import 'status_effect_processor.dart';
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
  final StatusEffectProcessor _statusProcessor;

  BattleEngine({
    required TurnManager turnManager,
    required DamageCalculator damageCalculator,
    required EnemyAi enemyAi,
    required Map<String, Skill> skills,
    required Map<String, Item> items,
    required Map<String, Equipment> equipment,
    StatusEffectProcessor? statusProcessor,
  })  : _turnManager = turnManager,
        _damageCalculator = damageCalculator,
        _enemyAi = enemyAi,
        _skills = skills,
        _items = items,
        _equipment = equipment,
        _statusProcessor = statusProcessor ?? StatusEffectProcessor();

  Stats _effectiveStats(Character hero) {
    final base = EquipmentSystem.computeEffectiveStats(hero, _equipment);
    if (hero.statusEffects.isEmpty) return base;
    final atkMult = _statusProcessor.getAttackMultiplier(hero.statusEffects);
    final defMult = _statusProcessor.getDefenseMultiplier(hero.statusEffects);
    return base.copyWith(
      attack: (base.attack * atkMult).round().clamp(1, 9999),
      magicAttack: (base.magicAttack * atkMult).round().clamp(1, 9999),
      defense: (base.defense * defMult).round().clamp(1, 9999),
      magicDefense: (base.magicDefense * defMult).round().clamp(1, 9999),
    );
  }

  Stats _effectiveEnemyStats(Enemy enemy) {
    if (enemy.statusEffects.isEmpty) return enemy.stats;
    final atkMult = _statusProcessor.getAttackMultiplier(enemy.statusEffects);
    final defMult = _statusProcessor.getDefenseMultiplier(enemy.statusEffects);
    return enemy.stats.copyWith(
      attack: (enemy.stats.attack * atkMult).round().clamp(1, 9999),
      magicAttack: (enemy.stats.magicAttack * atkMult).round().clamp(1, 9999),
      defense: (enemy.stats.defense * defMult).round().clamp(1, 9999),
      magicDefense: (enemy.stats.magicDefense * defMult).round().clamp(1, 9999),
    );
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
    // Tick down status effect durations at round start (after round 1)
    final tickMessages = <String>[];
    var tickedState = state;
    if (state.roundNumber > 1) {
      tickedState =
          _statusProcessor.tickDownDurations(state, tickMessages);
    }

    final turnOrder = _turnManager.calculateTurnOrder(
      party: tickedState.party,
      enemies: tickedState.enemies,
    );

    if (turnOrder.isEmpty) return tickedState;

    final firstActorId = turnOrder.first;
    final isHero = tickedState.party.any((h) => h.id == firstActorId);

    return tickedState.copyWith(
      turnOrder: turnOrder,
      currentTurnIndex: 0,
      phase: isHero ? BattlePhase.playerInput : BattlePhase.enemyTurn,
      activeHeroId: isHero ? firstActorId : null,
      battleLog: [...tickedState.battleLog, ...tickMessages],
    );
  }

  BattleState advanceTurn(BattleState state) {
    final nextIndex = state.currentTurnIndex + 1;

    if (nextIndex >= state.turnOrder.length) {
      // Round complete — reset defend flags and start new round
      final resetParty =
          state.party.map((h) => h.copyWith(isDefending: false)).toList();
      final resetEnemies = state.enemies;
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

    // Process status effects at turn start (DoT, stun)
    var currentState = state.copyWith(currentTurnIndex: nextIndex);
    final tickResult =
        _statusProcessor.processTurnStart(currentState, nextActorId);
    currentState = tickResult.state;

    if (tickResult.messages.isNotEmpty) {
      currentState = currentState.copyWith(
        battleLog: [...currentState.battleLog, ...tickResult.messages],
      );
    }

    // Check if DoT killed the actor
    if (!_isActorAlive(currentState, nextActorId)) {
      // Check victory/defeat after DoT kill
      if (currentState.enemies.every((e) => !e.isAlive)) {
        final totalXp =
            currentState.enemies.fold<int>(0, (sum, e) => sum + e.xpReward);
        final totalGold =
            currentState.enemies.fold<int>(0, (sum, e) => sum + e.goldReward);
        return currentState.copyWith(
          phase: BattlePhase.victory,
          result: BattleResult(totalXp: totalXp, totalGold: totalGold),
          battleLog: [...currentState.battleLog, 'Victory!'],
        );
      }
      if (currentState.party.every((h) => !h.isAlive)) {
        return currentState.copyWith(
          phase: BattlePhase.defeat,
          battleLog: [...currentState.battleLog, 'Defeat...'],
        );
      }
      return advanceTurn(currentState);
    }

    // If stunned, skip this actor's turn
    if (tickResult.isStunned) {
      return advanceTurn(currentState);
    }

    final isHero = currentState.party.any((h) => h.id == nextActorId);

    return currentState.copyWith(
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
        defenseStat: _effectiveEnemyStats(enemy).defense,
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
        attackStat: _effectiveEnemyStats(enemy).attack,
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
      // Apply buff effects to all living allies
      var resultState = state.copyWith(party: updatedParty);
      if (skill.appliesEffect != null) {
        for (final ally in resultState.party) {
          if (!ally.isAlive) continue;
          resultState = _tryApplyStatusEffect(
            state: resultState,
            skill: skill,
            actorId: action.actorId,
            targetId: ally.id,
            targetIsHero: true,
            messages: messages,
          );
        }
      }
      return resultState;
    }

    // Healing targets allies
    final target = state.party.firstWhere((h) => h.id == targetId);

    // Handle revive
    if ((skill.id == 'healer_revive' || skill.id == 'healer_resurrection') &&
        !target.isAlive) {
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

    var resultState = state.copyWith(party: updatedParty);
    // Apply buff effects to the healed ally
    if (skill.appliesEffect != null) {
      resultState = _tryApplyStatusEffect(
        state: resultState,
        skill: skill,
        actorId: action.actorId,
        targetId: targetId,
        targetIsHero: true,
        messages: messages,
      );
    }
    return resultState;
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

        final enemyStats = _effectiveEnemyStats(enemy);
        DamageResult dmg;
        if (skill.type == SkillType.magical) {
          dmg = _damageCalculator.calculateMagicalDamage(
            magicAttackStat: heroStats.magicAttack,
            magicDefenseStat: enemyStats.magicDefense,
            skillPower: skill.power,
            skillElement: skill.element,
            targetWeaknesses: enemy.weaknesses,
            targetResistances: enemy.resistances,
          );
        } else {
          dmg = _damageCalculator.calculatePhysicalDamage(
            attackStat: heroStats.attack,
            defenseStat: enemyStats.defense,
            skillPower: skill.power,
            accuracy: skill.accuracy,
            skillElement: skill.element,
            targetWeaknesses: enemy.weaknesses,
            targetResistances: enemy.resistances,
          );
        }

        if (!dmg.isMiss) {
          final newHp =
              (enemy.currentHp - dmg.damage).clamp(0, enemy.stats.maxHp);
          updatedEnemies[i] = enemy.copyWith(currentHp: newHp);
          final elemText = dmg.elementalMultiplier > 1.0
              ? ' Super effective!'
              : dmg.elementalMultiplier < 1.0
                  ? ' Not very effective...'
                  : '';
          messages.add('${enemy.name} takes ${dmg.damage} damage!$elemText');

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

      // Apply status effects to surviving enemies
      var resultState = state.copyWith(enemies: updatedEnemies);
      if (skill.appliesEffect != null) {
        for (final enemy in resultState.enemies) {
          if (!enemy.isAlive) continue;
          resultState = _tryApplyStatusEffect(
            state: resultState,
            skill: skill,
            actorId: action.actorId,
            targetId: enemy.id,
            targetIsHero: false,
            messages: messages,
          );
        }
      }
      return resultState;
    } else {
      // Enemy AoE hits all heroes
      final enemy = state.enemies.firstWhere((e) => e.id == action.actorId);
      final enemyStats = _effectiveEnemyStats(enemy);
      var updatedParty = List<Character>.from(state.party);

      for (var i = 0; i < updatedParty.length; i++) {
        final hero = updatedParty[i];
        if (!hero.isAlive) continue;

        final heroStats = _effectiveStats(hero);
        DamageResult dmg;
        if (skill.type == SkillType.magical) {
          dmg = _damageCalculator.calculateMagicalDamage(
            magicAttackStat: enemyStats.magicAttack,
            magicDefenseStat: heroStats.magicDefense,
            skillPower: skill.power,
            isDefending: hero.isDefending,
          );
        } else {
          dmg = _damageCalculator.calculatePhysicalDamage(
            attackStat: enemyStats.attack,
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

      // Apply status effects to surviving heroes
      var resultState = state.copyWith(party: updatedParty);
      if (skill.appliesEffect != null) {
        for (final hero in resultState.party) {
          if (!hero.isAlive) continue;
          resultState = _tryApplyStatusEffect(
            state: resultState,
            skill: skill,
            actorId: action.actorId,
            targetId: hero.id,
            targetIsHero: true,
            messages: messages,
          );
        }
      }
      return resultState;
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
      final enemyStats = _effectiveEnemyStats(enemy);

      DamageResult dmg;
      if (skill.type == SkillType.magical) {
        dmg = _damageCalculator.calculateMagicalDamage(
          magicAttackStat: heroStats.magicAttack,
          magicDefenseStat: enemyStats.magicDefense,
          skillPower: skill.power,
          skillElement: skill.element,
          targetWeaknesses: enemy.weaknesses,
          targetResistances: enemy.resistances,
        );
      } else {
        dmg = _damageCalculator.calculatePhysicalDamage(
          attackStat: heroStats.attack,
          defenseStat: enemyStats.defense,
          skillPower: skill.power,
          accuracy: skill.accuracy,
          skillElement: skill.element,
          targetWeaknesses: enemy.weaknesses,
          targetResistances: enemy.resistances,
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
        final elemText = dmg.elementalMultiplier > 1.0
            ? ' Super effective!'
            : dmg.elementalMultiplier < 1.0
                ? ' Not very effective...'
                : '';
        messages.add(
            '$actorName uses ${skill.name} on ${enemy.name} for ${dmg.damage} damage!$critText$elemText');

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

        var resultState = state.copyWith(enemies: updatedEnemies);
        // Apply status effect if target is alive
        if (newHp > 0) {
          resultState = _tryApplyStatusEffect(
            state: resultState,
            skill: skill,
            actorId: action.actorId,
            targetId: targetId,
            targetIsHero: false,
            messages: messages,
          );
        }
        return resultState;
      }
    } else {
      final enemy = state.enemies.firstWhere((e) => e.id == action.actorId);
      final enemyStats = _effectiveEnemyStats(enemy);
      final hero = state.party.firstWhere((h) => h.id == targetId);
      final heroStats = _effectiveStats(hero);

      DamageResult dmg;
      if (skill.type == SkillType.magical) {
        dmg = _damageCalculator.calculateMagicalDamage(
          magicAttackStat: enemyStats.magicAttack,
          magicDefenseStat: heroStats.magicDefense,
          skillPower: skill.power,
          isDefending: hero.isDefending,
        );
      } else {
        dmg = _damageCalculator.calculatePhysicalDamage(
          attackStat: enemyStats.attack,
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

        var resultState = state.copyWith(party: updatedParty);
        // Apply status effect if target is alive
        if (newHp > 0) {
          resultState = _tryApplyStatusEffect(
            state: resultState,
            skill: skill,
            actorId: action.actorId,
            targetId: targetId,
            targetIsHero: true,
            messages: messages,
          );
        }
        return resultState;
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

  // --- Status effect application helper ---

  /// Try to apply a skill's status effect to a target.
  /// Returns updated party/enemies lists and messages.
  BattleState _tryApplyStatusEffect({
    required BattleState state,
    required Skill skill,
    required String actorId,
    required String targetId,
    required bool targetIsHero,
    required List<String> messages,
  }) {
    if (skill.appliesEffect == null) return state;
    if (!_statusProcessor.rollEffect(skill.effectChance)) return state;

    final effect = StatusEffect(
      type: skill.appliesEffect!,
      duration: skill.effectDuration,
      value: skill.effectValue,
      sourceId: actorId,
    );

    if (targetIsHero) {
      final idx = state.party.indexWhere((h) => h.id == targetId);
      if (idx < 0) return state;
      final hero = state.party[idx];
      final newEffects =
          _statusProcessor.applyEffect(hero.statusEffects, effect);
      final updatedParty = List<Character>.from(state.party);
      updatedParty[idx] = hero.copyWith(statusEffects: newEffects);
      messages.add('${hero.name} is afflicted with ${effect.displayName}!');
      return state.copyWith(party: updatedParty);
    } else {
      final idx = state.enemies.indexWhere((e) => e.id == targetId);
      if (idx < 0) return state;
      final enemy = state.enemies[idx];
      final newEffects =
          _statusProcessor.applyEffect(enemy.statusEffects, effect);
      final updatedEnemies = List<Enemy>.from(state.enemies);
      updatedEnemies[idx] = enemy.copyWith(statusEffects: newEffects);
      messages.add('${enemy.name} is afflicted with ${effect.displayName}!');
      return state.copyWith(enemies: updatedEnemies);
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
